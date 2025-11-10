import 'package:dio/dio.dart';
import 'api_client.dart';
import 'secure_storage.dart';

class AuthService {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthService(this._api, this._storage);

  /// 회원가입
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

  /// 로그인
  /// - 성공 시 JWT를 secure storage에 저장
  /// - 실패 시 사람이 읽을 수 있는 "문자열" 예외를 던짐 (Exception: prefix 안 붙게)
  Future<String> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _api.dio.post(
        '/api/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = res.data;
      if (data is Map && data['token'] is String) {
        final token = data['token'] as String;
        await _storage.saveToken(token);
        return token;
      }

      throw '로그인 응답 형식이 올바르지 않습니다.';
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      String msg = '로그인 실패';

      if (status == 400 || status == 401) {
        final body = e.response?.data;
        if (body is Map && body['message'] is String) {
          msg = body['message'] as String;
        } else {
          msg = '아이디 또는 비밀번호가 올바르지 않습니다.';
        }
      } else if (e.message != null) {
        msg = '로그인 실패: ${e.message}';
      }

      throw msg;
    } catch (e) {
      throw '로그인 중 오류가 발생했습니다: $e';
    }
  }

  /// 현재 저장된 JWT 가져오기 (AuthState에서 사용)
  Future<String?> getToken() async {
    return _storage.readToken();
  }

  /// /api/auth/me 호출해서 유저 프로필 조회
  Future<Map<String, dynamic>> me() async {
    final res = await _api.dio.get('/api/auth/me');
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// OAuth 콜백 등에서 받은 토큰 직접 저장
  Future<void> saveTokenFromCallback(String token) async {
    await _storage.saveToken(token);
  }

  /// 로그아웃
  Future<void> logout() async {
    await _storage.deleteToken();
  }
}
