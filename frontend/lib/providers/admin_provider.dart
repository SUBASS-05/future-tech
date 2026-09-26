package:flutter/material.dart;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<dynamic> _pendingRequests = [];

  bool get isLoading => _isLoading;
  List<dynamic> get pendingRequests => _pendingRequests;

  Future<void> fetchPendingRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/admin/requests/pending');
      if (response.statusCode == 200) {
        _pendingRequests = jsonDecode(response.body);
      }
    } catch (e) { print(e); }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> approveStudent(int studentId) async {
    try {
      final response = await _apiService.post('/admin/requests/$studentId/approve', {});
      if (response.statusCode == 200) {
        await fetchPendingRequests();
        return true;
      }
    } catch (e) { print(e); }
    return false;
  }

  Future<bool> rejectStudent(int studentId) async {
    try {
      final response = await _apiService.post('/admin/requests/$studentId/reject', {});
      if (response.statusCode == 200) {
        await fetchPendingRequests();
        return true;
      }
    } catch (e) { print(e); }
    return false;
  }
}
