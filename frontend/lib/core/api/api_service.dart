import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/secure_storage/secure_storage.dart';

class ApiService {
  // Current Wi-Fi IPv4 address of host server
  static const String baseUrl = 'http://192.168.31.149:8080/api';
  static const Duration timeoutDuration = Duration(seconds: 15);

  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    ).timeout(timeoutDuration);
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.get(url, headers: headers).timeout(timeoutDuration);
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    ).timeout(timeoutDuration);
  }

  Future<http.Response> patch(String endpoint, [Map<String, dynamic>? body]) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.patch(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(timeoutDuration);
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.delete(url, headers: headers).timeout(timeoutDuration);
  }

  Future<http.StreamedResponse> postMultipart(String endpoint, String filePath, String fileField) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final token = await SecureStorage.getToken();
    var request = http.MultipartRequest('POST', url);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    return await request.send();
  }

  Future<http.StreamedResponse> postMultipartBytes(String endpoint, List<int> bytes, String filename, String fileField) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final token = await SecureStorage.getToken();
    var request = http.MultipartRequest('POST', url);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: filename));
    return await request.send();
  }

  Future<http.StreamedResponse> postMultipartWithFields(
      String endpoint, Map<String, String> fields, List<int> fileBytes, String filename, String fileField) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final token = await SecureStorage.getToken();
    var request = http.MultipartRequest('POST', url);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    request.files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: filename));
    return await request.send();
  }
}
