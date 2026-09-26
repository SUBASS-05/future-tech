import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../data/secure_storage/secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _error;
  String? _role;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get role => _role;

  bool get isAuthenticated => _role != null;

  Future<void> checkAuthStatus() async {
    final token = await SecureStorage.getToken();
    final userRole = await SecureStorage.getRole();
    if (token != null && userRole != null) {
      _role = userRole;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userRole = data['role']; // ADMIN or STUDENT

        await SecureStorage.saveToken(token);
        await SecureStorage.saveRole(userRole);
        
        _role = userRole;
        _error = null;
        _setLoading(false);
        return true;
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Login failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerStudent(String fullName, String email, String password, String institutionName) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/auth/register', {
        'fullName': fullName,
        'email': email,
        'password': password,
        'institutionName': institutionName,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _error = null;
        _setLoading(false);
        return true;
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Registration failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    _role = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
