import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _key = 'auth_token';
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _key, value: token);
  Future<String?> readToken() => _storage.read(key: _key);
  Future<void> deleteToken() => _storage.delete(key: _key);
}
