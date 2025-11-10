import 'package:dio/dio.dart';
import 'api_client.dart';
import 'secure_storage.dart';

class AuthService {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthService(this._api, this._storage);

  /// 🔹 토큰 읽기 (auth_provider에서 사용)
  Future<String?> getToken() => _storage.readToken();

  /// 🔹 회원가입
  Future<void> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    await _api.dio.post(
      '/api/auth/signup',
      data: {
        'username': username,
        'email': email,
        'password': password,
      },
    );
  }

  /// 🔹 로그인 + 토큰 저장
  Future<String> login({
    required String username,
    required String password,
  }) async {
    final res = await _api.dio.post(
      '/api/auth/login',
      data: {
        'username': username,
        'password': password,
      },
    );

    // ✅ 응답 파싱 안전하게
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('로그인 실패: ${res.statusCode} ${res.data}');
    }

    final map = res.data as Map;
    final token = (map['token'] as String?) ?? '';
    if (token.isEmpty) {
      throw Exception('토큰이 비어 있습니다.');
    }

    // ✅ 저장
    await _storage.saveToken(token);
    print('✅ 로그인 성공, 토큰 저장됨: $token');
    return token;
  }

  /// 🔹 내 프로필 조회 (/api/auth/me)
  Future<Map<String, dynamic>> me() async {
    final res = await _api.dio.get('/api/auth/me');
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// 🔹 콜백에서 직접 토큰 저장 (OAuth)
  Future<void> saveTokenFromCallback(String token) async {
    await _storage.saveToken(token);
  }

  /// 🔹 로그아웃 (토큰 삭제)
  Future<void> logout() async {
    await _storage.deleteToken();
    print('🚪 로그아웃: 토큰 삭제 완료');
  }
}
