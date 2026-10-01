import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  // Top Admin Fees State
  int _unseenPaymentCount = 0;
  Map<String, dynamic>? _adminFeesSummary;
  bool _isFeesLoading = false;
  String? _feesError;

  int get unseenPaymentCount => _unseenPaymentCount;
  Map<String, dynamic>? get adminFeesSummary => _adminFeesSummary;
  bool get isFeesLoading => _isFeesLoading;
  String? get feesError => _feesError;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ---- PROFILE MANAGEMENT ----

  Future<void> fetchProfile() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/admin/profile');
      if (response.statusCode == 200 || response.statusCode == 206) {
        final data = jsonDecode(response.body);
        _adminProfile = data['profile'] is Map<String, dynamic> ? data['profile'] : data;
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
    return await updateProfile(profileData);
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    try {
      final response = await _apiService.put('/admin/profile', profileData);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _adminProfile = data['profile'] is Map<String, dynamic> ? data['profile'] : data;
        _missingFields = List<String>.from(data['missingFields'] ?? []);
        _error = null;
        notifyListeners();
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

  Future<bool> uploadProfilePhoto(String filePath) async {
    _setLoading(true);
    try {
      final streamedResponse = await _apiService.postMultipart('/admin/profile/photo', filePath, 'file');
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _adminProfile = data['profile'] is Map<String, dynamic> ? data['profile'] : data;
        _missingFields = List<String>.from(data['missingFields'] ?? []);
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Unable to upload profile photo. Please try again.';
        return false;
      }
    } catch (e) {
      _error = 'Unable to upload profile photo. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProfilePhoto() async {
    _setLoading(true);
    try {
      final response = await _apiService.delete('/admin/profile/photo');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _adminProfile = data['profile'] is Map<String, dynamic> ? data['profile'] : data;
        _missingFields = List<String>.from(data['missingFields'] ?? []);
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = jsonDecode(response.body)['message'] ?? 'Failed to delete photo';
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

  // ---- TOP ADMIN FEES MANAGEMENT ----

  Future<void> fetchUnseenNotificationCount() async {
    try {
      final response = await _apiService.get('/admin/fees/notifications/count');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _unseenPaymentCount = data['newPayments'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  Future<void> markNotificationsSeen() async {
    try {
      final response = await _apiService.patch('/admin/fees/notifications/mark-seen');
      if (response.statusCode == 200) {
        _unseenPaymentCount = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notifications seen: $e');
    }
  }

  Future<void> fetchAdminFeesSummary({String filter = 'today', String search = ''}) async {
    _isFeesLoading = true;
    _feesError = null;
    notifyListeners();
    try {
      final queryParams = StringBuffer('filter=$filter');
      if (search.trim().isNotEmpty) {
        queryParams.write('&search=${Uri.encodeComponent(search.trim())}');
      }
      final response = await _apiService.get('/admin/fees/summary?$queryParams');
      if (response.statusCode == 200) {
        _adminFeesSummary = jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        _feesError = '403 FORBIDDEN: Only TOP_ADMIN can access fee management.';
      } else {
        _feesError = 'Failed to load fee summary (${response.statusCode})';
      }
    } catch (e) {
      _feesError = 'Connection error: $e';
    } finally {
      _isFeesLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchAdminStudentFeeDetails(String studentId) async {
    try {
      final response = await _apiService.get('/admin/fees/student/$studentId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching student fee details: $e');
    }
    return null;
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
    } catch (e) { debugPrint(e.toString()); }
    _setLoading(false);
  }

  Future<bool> approveStudent(int studentId) async {
    try {
      final response = await _apiService.post('/admin/student-requests/$studentId/approve', {});
      if (response.statusCode == 200) {
        await fetchPendingRequests();
        return true;
      }
    } catch (e) { debugPrint(e.toString()); }
    return false;
  }

  Future<bool> rejectStudent(int studentId) async {
    try {
      final response = await _apiService.post('/admin/student-requests/$studentId/reject', {});
      if (response.statusCode == 200) {
        await fetchPendingRequests();
        return true;
      }
    } catch (e) { debugPrint(e.toString()); }
    return false;
  }

  // ---- TASKS & STUDENT ASSIGNMENT ----

  List<dynamic> _students = [];
  List<dynamic> _tasks = [];

  List<dynamic> get students => _students;
  List<dynamic> get tasks => _tasks;

  Future<void> fetchStudents() async {
    try {
      final response = await _apiService.get('/admin/students');
      if (response.statusCode == 200) {
        _students = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchStudents error: $e');
    }
  }

  Future<void> fetchTasks() async {
    try {
      final response = await _apiService.get('/admin/tasks');
      if (response.statusCode == 200) {
        _tasks = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchTasks error: $e');
    }
  }

  Future<List<dynamic>> fetchTaskHistory() async {
    try {
      final response = await _apiService.get('/admin/tasks/history');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('fetchTaskHistory error: $e');
    }
    return [];
  }

  Future<dynamic> getTaskProgress(dynamic taskId) async {
    try {
      final response = await _apiService.get('/admin/tasks/$taskId/progress');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('getTaskProgress error: $e');
    }
    return null;
  }

  Future<String?> createTask(
    String title, 
    String description, 
    String priority, 
    DateTime? dueDate, 
    int? estimatedMinutes, 
    List<int> studentIds
  ) async {
    _setLoading(true);
    try {
      final dueAtIso = dueDate != null ? dueDate.toUtc().toIso8601String() : DateTime.now().add(const Duration(days: 1)).toUtc().toIso8601String();
      final body = {
        'title': title,
        'description': description,
        'priority': priority,
        'dueAt': dueAtIso,
        'estimatedMinutes': estimatedMinutes,
        'studentIds': studentIds,
      };
      final response = await _apiService.post('/admin/tasks', body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _error = null;
        await fetchTasks();
        return null;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to create task';
        return _error;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      return _error;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteTask(dynamic taskId) async {
    _setLoading(true);
    try {
      final response = await _apiService.delete('/admin/tasks/$taskId');
      if (response.statusCode == 200) {
        _error = null;
        await fetchTasks();
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to delete task';
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
