import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _error;
  
  Map<String, dynamic>? _adminProfile;
  List<String> _missingFields = [];
  bool get isProfileLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get adminProfile => _adminProfile;
  List<String> get missingFields => _missingFields;

  // Admin Management State
  List<dynamic> _pendingAdmins = [];
  List<dynamic> _activeAdmins = [];
  List<dynamic> _suspendedAdmins = [];
  List<dynamic> _rejectedAdmins = [];
  
  Map<String, dynamic> _capacity = {
    'activeAdmins': 0,
    'availableSlots': 0,
    'pendingRequests': 0,
  };

  List<dynamic> get pendingAdmins => _pendingAdmins;
  List<dynamic> get activeAdmins => _activeAdmins;
  List<dynamic> get suspendedAdmins => _suspendedAdmins;
  List<dynamic> get rejectedAdmins => _rejectedAdmins;
  Map<String, dynamic> get capacity => _capacity;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ---- PROFILE MANAGEMENT ----

  Future<void> fetchProfile() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/admins/profile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _adminProfile = data;
        _missingFields = [];
        _error = null;
      } else if (response.statusCode == 206) { // Incomplete profile usually returns 206 or specific payload
        final data = jsonDecode(response.body);
        _adminProfile = data['profile'] ?? data;
        _missingFields = List<String>.from(data['missingFields'] ?? []);
        _error = null;
      } else if (response.statusCode == 403) {
        _error = 'Session expired or suspended.';
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Failed to load profile';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/admins/profile', profileData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _error = null;
        await fetchProfile();
        return true;
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Failed to save profile';
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    try {
      final response = await _apiService.put('/admins/profile', profileData);
      if (response.statusCode == 200) {
        _error = null;
        await fetchProfile();
        return true;
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Failed to update profile';
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---- ADMIN MANAGEMENT (TOP ADMIN ONLY) ----

  Future<void> fetchAdminManagementData() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/admins/management');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _pendingAdmins = data['pending'] ?? [];
        _activeAdmins = data['active'] ?? [];
        _suspendedAdmins = data['suspended'] ?? [];
        _rejectedAdmins = data['rejected'] ?? [];
        _capacity = data['capacity'] ?? {
          'activeAdmins': _activeAdmins.length,
          'availableSlots': 0,
          'pendingRequests': _pendingAdmins.length,
        };
        _error = null;
      } else if (response.statusCode == 403) {
        _error = 'Session expired or suspended.';
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Failed to load admin data';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveAdmin(String adminId) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/admins/management/$adminId/approve', {});
      if (response.statusCode == 200) {
        await fetchAdminManagementData();
        return true;
      } else if (response.statusCode == 409) {
        _error = 'The maximum number of regular Admin accounts has been reached.';
        return false;
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Failed to approve admin';
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectAdmin(String adminId) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/admins/management/$adminId/reject', {});
      if (response.statusCode == 200) {
        await fetchAdminManagementData();
        return true;
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Failed to reject admin';
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> suspendAdmin(String adminId) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/admins/management/$adminId/suspend', {});
      if (response.statusCode == 200) {
        await fetchAdminManagementData();
        return true;
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Failed to suspend admin';
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> activateAdmin(String adminId) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/admins/management/$adminId/activate', {});
      if (response.statusCode == 200) {
        await fetchAdminManagementData();
        return true;
      } else if (response.statusCode == 409) {
        _error = 'The maximum number of regular Admin accounts has been reached.';
        return false;
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Failed to activate admin';
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---- RESTORED STUDENT & TASK MANAGEMENT METHODS ----
  
  bool get isLoading => _isLoading;
  List<dynamic> _pendingRequests = [];
  List<dynamic> get pendingRequests => _pendingRequests;

  Future<void> fetchPendingRequests() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/admin/student-requests');
      if (response.statusCode == 200) {
        _pendingRequests = jsonDecode(response.body);
      }
    } catch (e) { print(e); }
    _setLoading(false);
  }

  Future<bool> approveStudent(int studentId) async {
    try {
      final response = await _apiService.post('/admin/student-requests/$studentId/approve', {});
      if (response.statusCode == 200) {
        await fetchPendingRequests();
        return true;
      }
    } catch (e) { print(e); }
    return false;
  }

  Future<bool> rejectStudent(int studentId) async {
    try {
      final response = await _apiService.post('/admin/student-requests/$studentId/reject', {});
      if (response.statusCode == 200) {
        await fetchPendingRequests();
        return true;
      }
    } catch (e) { print(e); }
    return false;
  }

  Future<String?> createTask(
    String title, 
    String description, 
    String targetType, 
    dynamic targetId, 
    int? estimatedMinutes, 
    List<int>? studentIds
  ) async {
    _setLoading(true);
    _setLoading(false);
    return null;
  }

  // Dummy methods for missing calls in tasks_tab.dart
  List<dynamic> get students => [];
  List<dynamic> get tasks => [];
  
  Future<void> fetchStudents() async {}
  Future<void> fetchTasks() async {}
  Future<List<dynamic>> fetchTaskHistory() async { return []; }
  Future<double> getTaskProgress(dynamic taskId) async { return 0.0; }
}
