import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _key = 'auth_token';
  final _secure = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_key, token);
    } else {
      await _secure.write(key: _key, value: token);
    }
  }

  Future<String?> readToken() async {
    if (kIsWeb) {
      final sp = await SharedPreferences.getInstance();
      return sp.getString(_key);
    } else {
      return await _secure.read(key: _key);
    }
  }

  Future<void> deleteToken() async {
    if (kIsWeb) {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_key);
    } else {
      await _secure.delete(key: _key);
    }
  }
}
