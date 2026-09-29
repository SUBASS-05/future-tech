import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'jwt_token';
  static const _keyRole = 'user_role';
  static const _keyProfileStatus = 'profile_status';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<void> saveRole(String role) async {
    await _storage.write(key: _keyRole, value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _keyRole);
  }

  static Future<void> saveProfileStatus(String status) async {
    await _storage.write(key: _keyProfileStatus, value: status);
  }

  static Future<String?> getProfileStatus() async {
    return await _storage.read(key: _keyProfileStatus);
  }

  static const _keyEmail = 'user_email';

  static Future<void> saveEmail(String email) async {
    await _storage.write(key: _keyEmail, value: email);
  }

  static Future<String?> getEmail() async {
    return await _storage.read(key: _keyEmail);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
