import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class StudentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _profile;
  List<dynamic> _tasks = [];
  List<dynamic> _fees = [];
  List<dynamic> _attendance = [];

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get profile => _profile;
  List<dynamic> get tasks => _tasks;
  List<dynamic> get fees => _fees;
  List<dynamic> get attendance => _attendance;

  Future<void> fetchAllData() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      fetchProfile(),
      fetchTasks(),
      fetchFees(),
      fetchAttendance()
    ]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _apiService.get('/student/profile');
      if (response.statusCode == 200) {
        _profile = jsonDecode(response.body);
      } else {
        _profile = {'error': 'Failed to fetch profile: \${response.statusCode} \${response.body}'};
      }
      notifyListeners();
    } catch (e) { 
      _profile = {'error': 'Connection error: \$e'};
      notifyListeners();
      print(e); 
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
        return null; // Success (no error string)
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
        return null; // Success
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
    } catch (e) { print(e); }
    return [];
  }

  Future<List<dynamic>> fetchDepartments(int institutionId) async {
    try {
      final response = await _apiService.get('/student/institutions/$institutionId/departments');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) { print(e); }
    return [];
  }

  Future<void> fetchTasks() async {
    try {
      final response = await _apiService.get('/student/tasks');
      if (response.statusCode == 200) {
        _tasks = jsonDecode(response.body);
      }
    } catch (e) { print(e); }
  }

  Future<bool> updateTaskStatus(int taskId, String status) async {
    try {
      final response = await _apiService.put('/student/tasks/$taskId/status', {'status': status});
      if (response.statusCode == 200) {
        await fetchTasks();
        return true;
      }
    } catch (e) { print(e); }
    return false;
  }

  Future<void> fetchFees() async {
    try {
      final response = await _apiService.get('/student/fees');
      if (response.statusCode == 200) {
        _fees = jsonDecode(response.body);
      }
    } catch (e) { print(e); }
  }

  Future<void> fetchAttendance() async {
    try {
      final response = await _apiService.get('/student/attendance');
      if (response.statusCode == 200) {
        _attendance = jsonDecode(response.body);
      }
    } catch (e) { print(e); }
  }
}
