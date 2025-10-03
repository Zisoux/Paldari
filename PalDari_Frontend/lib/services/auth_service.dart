import 'package:dio/dio.dart';
import '../config.dart';
import 'api_client.dart';
import 'secure_storage.dart';

class AuthService {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthService(this._api, this._storage);

  Future<void> signup({required String username, required String email, required String password}) async {
    await _api.dio.post('/api/auth/signup', data: {
      'username': username, 'email': email, 'password': password,
    });
  }

  Future<String> login({required String username, required String password}) async {
    final res = await _api.dio.post('/api/auth/login', data: {
      'username': username, 'password': password,
    });
    final token = (res.data as Map)['token'] as String;
    await _storage.saveToken(token);
    return token;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _api.dio.get('/api/auth/me');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> saveTokenFromCallback(String token) => _storage.saveToken(token);
  Future<void> logout() => _storage.deleteToken();
}
