import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/websocket/sync_event.dart';
import '../core/websocket/websocket_service.dart';

class StudentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  StreamSubscription<SyncEvent>? _eventSubscription;

  StudentProvider() {
    initSync();
  }

  void initSync() {
    _eventSubscription?.cancel();
    _eventSubscription = WebSocketService().eventStream.listen(_handleSyncEvent);
  }

  void _handleSyncEvent(SyncEvent event) {
    debugPrint('[StudentProvider] Real-time event received: ${event.eventType}');
    switch (event.eventType) {
      case 'WS_RECONNECTED':
        fetchAllData();
        fetchLeaveRequests();
        break;
      case 'STUDENT_APPROVED':
      case 'STUDENT_REJECTED':
      case 'STUDENT_PROFILE_UPDATED':
      case 'USER_DATA_UPDATED':
        fetchProfile();
        break;
      case 'PAYMENT_CREATED':
      case 'PAYMENT_UPDATED':
      case 'PAYMENT_STATUS_UPDATED':
      case 'FEE_STATUS_UPDATED':
        fetchFees();
        break;
      case 'ATTENDANCE_UPDATED':
        fetchAttendance();
        break;
      case 'TASK_CREATED':
      case 'TASK_UPDATED':
      case 'TASK_DELETED':
      case 'TASK_STATUS_UPDATED':
        fetchTasks();
        break;
      case 'LEAVE_REQUEST_CREATED':
      case 'LEAVE_REQUEST_UPDATED':
      case 'LEAVE_REQUEST_APPROVED':
      case 'LEAVE_REQUEST_REJECTED':
        fetchLeaveRequests();
        fetchAttendance();
        break;
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
  bool _isLoading = false;
  Map<String, dynamic>? _profile;
  List<dynamic> _tasks = [];
  Map<String, dynamic>? _feeSummary;
  List<dynamic> _fees = [];
  List<dynamic> _attendance = [];

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get profile => _profile;
  List<dynamic> get tasks => _tasks;
  Map<String, dynamic>? get feeSummary => _feeSummary;
  List<dynamic> get fees => _fees;
  List<dynamic> get attendance => _attendance;

  Future<void> fetchAllData({bool silent = false}) async {
    if (!silent && _profile == null) {
      _isLoading = true;
      notifyListeners();
    }
    await Future.wait([
      fetchProfile(),
      fetchTasks(),
      fetchFees(),
      fetchAttendance()
    ]);
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _apiService.get('/student/profile');
      if (response.statusCode == 200) {
        _profile = jsonDecode(response.body);
      } else {
        _profile = {'error': 'Failed to fetch profile: ${response.statusCode} ${response.body}'};
      }
      notifyListeners();
    } catch (e) { 
      _profile = {'error': 'Connection error: $e'};
      notifyListeners();
      debugPrint(e.toString());
    }
  }

  Future<String?> updateProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put('/student/profile', profileData);
      _isLoading = false;
      notifyListeners();
      
      if (response.statusCode == 200) {
        await fetchProfile();
        return null;
      } else {
        return jsonDecode(response.body)['message'] ?? 'Failed to update profile';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Connection error: $e';
    }
  }

  Future<String?> uploadProfilePhoto(List<int> bytes, String filename) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.postMultipartBytes('/student/profile/photo', bytes, filename, 'file');
      _isLoading = false;
      if (response.statusCode == 200) {
        await fetchProfile();
        return null;
      } else {
        final respStr = await response.stream.bytesToString();
        try {
          return jsonDecode(respStr)['message'] ?? 'Failed to upload photo';
        } catch (_) {
          return 'Failed to upload photo';
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Connection error: $e';
    }
  }

  Future<String?> removeProfilePhoto() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.delete('/student/profile/photo');
      _isLoading = false;
      if (response.statusCode == 200) {
        await fetchProfile();
        return null;
      } else {
        return jsonDecode(response.body)['message'] ?? 'Failed to remove photo';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Connection error: $e';
    }
  }
  
  Future<List<dynamic>> fetchInstitutions() async {
    try {
      final response = await _apiService.get('/student/institutions');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) { debugPrint(e.toString()); }
    return [];
  }

  Future<List<dynamic>> fetchDepartments(int institutionId) async {
    try {
      final response = await _apiService.get('/student/institutions/$institutionId/departments');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) { debugPrint(e.toString()); }
    return [];
  }

  Future<void> fetchTasks() async {
    try {
      final response = await _apiService.get('/student/tasks');
      if (response.statusCode == 200) {
        _tasks = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<String?> updateTaskStatus(int taskId, String status) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put('/student/tasks/$taskId/status', {'status': status});
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        await fetchTasks();
        return null;
      } else {
        try {
          return jsonDecode(response.body)['message'] ?? 'Failed to update status';
        } catch (_) {
          return 'Failed to update task status (${response.statusCode})';
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint(e.toString());
      return 'Connection error: $e';
    }
  }

  Future<void> fetchFees() async {
    try {
      final response = await _apiService.get('/student/fees');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          _feeSummary = data;
          _fees = data['payments'] ?? [];
        } else if (data is List) {
          _fees = data;
        }
        notifyListeners();
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<String?> submitPayment(double amount, List<int> fileBytes, String filename) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.postMultipartWithFields(
        '/student/fees/payments',
        {'amount': amount.toStringAsFixed(2)},
        fileBytes,
        filename,
        'file',
      );
      final respStr = await response.stream.bytesToString();
      _isLoading = false;

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(respStr);
          if (data is Map<String, dynamic>) {
            _feeSummary = data;
            _fees = data['payments'] ?? [];
          }
        } catch (_) {
          await fetchFees();
        }
        notifyListeners();
        return null; // Success
      } else {
        notifyListeners();
        try {
          final errMap = jsonDecode(respStr);
          return errMap['message'] ?? 'Failed to submit payment';
        } catch (_) {
          return 'Failed to submit payment (${response.statusCode})';
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Connection error: $e';
    }
  }

  Map<String, dynamic>? _attendanceSummary;
  Map<String, dynamic>? get attendanceSummary => _attendanceSummary;

  List<dynamic> _leaveRequests = [];
  List<dynamic> get leaveRequests => _leaveRequests;

  Future<void> fetchAttendance() async {
    try {
      final response = await _apiService.get('/student/attendance/summary');
      if (response.statusCode == 200) {
        _attendanceSummary = jsonDecode(response.body);
        _attendance = _attendanceSummary?['history'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchAttendance error: $e');
    }
  }

  Future<void> fetchLeaveRequests() async {
    try {
      final response = await _apiService.get('/student/leaves');
      if (response.statusCode == 200) {
        _leaveRequests = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchLeaveRequests error: $e');
    }
  }

  Future<String?> applyLeave(DateTime startDate, DateTime endDate, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      final startStr = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      final endStr = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      final body = {
        'startDate': startStr,
        'endDate': endStr,
        'reason': reason,
      };
      final response = await _apiService.post('/student/leaves', body);
      _isLoading = false;
      notifyListeners();
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchLeaveRequests();
        return null;
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Failed to submit leave request';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Connection error: $e';
    }
  }
}
