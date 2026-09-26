import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'jwt_token';
  static const _keyRole = 'user_role';

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

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
