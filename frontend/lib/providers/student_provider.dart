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
      }
    } catch (e) { print(e); }
  }

  Future<String?> updateProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put('/student/profile', profileData);
      _isLoading = false;
      notifyListeners();
      
      if (response.statusCode == 200) {
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
