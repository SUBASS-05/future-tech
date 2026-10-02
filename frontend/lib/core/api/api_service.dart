import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../data/secure_storage/secure_storage.dart';

class ApiService {
  static String _currentBaseUrl = 'http://192.168.31.149:8080/api';
  static const Duration timeoutDuration = Duration(seconds: 8);

  static String get baseUrl => _currentBaseUrl;

  static Future<void> setCustomBaseUrl(String url) async {
    String formatted = url.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }
    if (!formatted.endsWith('/api')) {
      formatted = formatted.endsWith('/') ? '${formatted}api' : '$formatted/api';
    }
    _currentBaseUrl = formatted;
    await SecureStorage.saveServerUrl(formatted);
  }

  static List<String> _getCandidateUrls(String? savedUrl) {
    final List<String> list = [];
    if (savedUrl != null && savedUrl.isNotEmpty) {
      list.add(savedUrl);
    }
    if (kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux || Platform.isIOS))) {
      list.add('http://localhost:8080/api');
      list.add('http://127.0.0.1:8080/api');
    }
    if (!kIsWeb && Platform.isAndroid) {
      list.add('http://10.0.2.2:8080/api');
    }
    list.add('http://192.168.31.149:8080/api');
    list.add(_currentBaseUrl);

    return list.toSet().toList();
  }

  static Future<bool> _pingUrl(String url) async {
    try {
      final response = await http
          .get(Uri.parse('$url/auth/health'))
          .timeout(const Duration(milliseconds: 1500));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<String> getValidBaseUrl({bool forceRediscover = false}) async {
    if (!forceRediscover) {
      final isHealthy = await _pingUrl(_currentBaseUrl);
      if (isHealthy) return _currentBaseUrl;
    }

    final savedUrl = await SecureStorage.getServerUrl();
    final candidates = _getCandidateUrls(savedUrl);

    final completer = Completer<String>();
    int pending = candidates.length;

    for (final candidate in candidates) {
      _pingUrl(candidate).then((healthy) {
        if (healthy && !completer.isCompleted) {
          completer.complete(candidate);
        } else {
          pending--;
          if (pending == 0 && !completer.isCompleted) {
            completer.complete(_currentBaseUrl);
          }
        }
      });
    }

    final workingUrl = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => _currentBaseUrl,
    );

    _currentBaseUrl = workingUrl;
    return workingUrl;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function(String base) requestFn,
  ) async {
    String currentBase = await getValidBaseUrl();
    try {
      return await requestFn(currentBase);
    } catch (e) {
      String newBase = await getValidBaseUrl(forceRediscover: true);
      return await requestFn(newBase);
    }
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return _executeWithRetry((base) {
      final url = Uri.parse('$base$endpoint');
      return http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(timeoutDuration);
    });
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return _executeWithRetry((base) {
      final url = Uri.parse('$base$endpoint');
      return http.get(url, headers: headers).timeout(timeoutDuration);
    });
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return _executeWithRetry((base) {
      final url = Uri.parse('$base$endpoint');
      return http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(timeoutDuration);
    });
  }

  Future<http.Response> patch(String endpoint, [Map<String, dynamic>? body]) async {
    final headers = await _getHeaders();
    return _executeWithRetry((base) {
      final url = Uri.parse('$base$endpoint');
      return http
          .patch(url, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(timeoutDuration);
    });
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return _executeWithRetry((base) {
      final url = Uri.parse('$base$endpoint');
      return http.delete(url, headers: headers).timeout(timeoutDuration);
    });
  }

  Future<http.StreamedResponse> postMultipart(String endpoint, String filePath, String fileField) async {
    final base = await getValidBaseUrl();
    final url = Uri.parse('$base$endpoint');
    final token = await SecureStorage.getToken();
    var request = http.MultipartRequest('POST', url);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    return await request.send();
  }

  Future<http.StreamedResponse> postMultipartBytes(String endpoint, List<int> bytes, String filename, String fileField) async {
    final base = await getValidBaseUrl();
    final url = Uri.parse('$base$endpoint');
    final token = await SecureStorage.getToken();
    var request = http.MultipartRequest('POST', url);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: filename));
    return await request.send();
  }

  Future<http.StreamedResponse> postMultipartWithFields(
      String endpoint, Map<String, String> fields, List<int> fileBytes, String filename, String fileField) async {
    final base = await getValidBaseUrl();
    final url = Uri.parse('$base$endpoint');
    final token = await SecureStorage.getToken();
    var request = http.MultipartRequest('POST', url);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    request.files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: filename));
    return await request.send();
  }
}
