import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../data/secure_storage/secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _error;
  String? _role;
  String? _profileStatus;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get role => _role;
  String? get profileStatus => _profileStatus;

  bool get isAuthenticated => _role != null;
  bool get isProfileCompleted => _profileStatus == 'COMPLETED';

  Future<void> checkAuthStatus() async {
    final token = await SecureStorage.getToken();
    final userRole = await SecureStorage.getRole();
    final pStatus = await SecureStorage.getProfileStatus();
    
    if (token != null && userRole != null) {
      _role = userRole;
      _profileStatus = pStatus ?? 'COMPLETED'; 
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password, String role) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
        'role': role,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userRole = data['userType']; // Match the backend AuthResponse DTO
        final profileStatus = data['profileStatus'] ?? 'COMPLETED';

        await SecureStorage.saveToken(token);
        await SecureStorage.saveRole(userRole);
        await SecureStorage.saveProfileStatus(profileStatus);
        await SecureStorage.saveEmail(email); // Save email for quick access across screens

        _role = userRole;
        _profileStatus = profileStatus;
        _error = null;
        _setLoading(false);
        
        return profileStatus; 
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Login failed';
        _setLoading(false);
        return null;
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException') || e.toString().contains('SocketException')) {
        _error = 'Server unreachable. Please verify phone & PC are on the same Wi-Fi and update Server IP in Settings.';
      } else {
        _error = 'Connection error: $e';
      }
      _setLoading(false);
      return null;
    }
  }

  void markProfileCompleted() {
    _profileStatus = 'COMPLETED';
    SecureStorage.saveProfileStatus('COMPLETED');
    notifyListeners();
  }

  Future<bool> registerStudent(String fullName, String email, String password, String institutionName, String role) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/auth/register', {
        'fullName': fullName,
        'email': email,
        'password': password,
        'institutionName': institutionName,
        'role': role,
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
      if (e.toString().contains('TimeoutException') || e.toString().contains('SocketException')) {
        _error = 'Server unreachable. Please verify phone & PC are on the same Wi-Fi and update Server IP in Settings.';
      } else {
        _error = 'Connection error: $e';
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerAdmin(String firstName, String lastName, String email, String password) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/auth/register-admin', {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
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
      if (e.toString().contains('TimeoutException') || e.toString().contains('SocketException')) {
        _error = 'Server unreachable. Please verify phone & PC are on the same Wi-Fi and update Server IP in Settings.';
      } else {
        _error = 'Connection error: $e';
      }
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    _role = null;
    notifyListeners();
  }

  void handleUnauthorized() {
    logout();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
