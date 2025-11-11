import 'package:dio/dio.dart';
import 'api_client.dart';
import 'secure_storage.dart';

class AuthService {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthService(this._api, this._storage);

  Dio get _dio => _api.dio;

  /// 회원가입
  Future<void> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/api/auth/signup',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (res.statusCode != 200) {
        throw '회원가입에 실패했습니다. (${res.statusCode})';
      }
    } on DioException catch (e) {
      final msg = _readErrorMessage(e) ?? '회원가입에 실패했습니다.';
      throw msg;
    } catch (e) {
      throw '회원가입 중 오류가 발생했습니다: $e';
    }
  }

  /// 로그인
  /// - 성공 시 accessToken / refreshToken 을 SecureStorage에 저장
  /// - 실패 시 사람이 읽을 수 있는 문자열 throw
  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/api/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (res.statusCode != 200) {
        throw '로그인에 실패했습니다. (${res.statusCode})';
      }

      final data = res.data;
      if (data is! Map) {
        throw '로그인 응답 형식이 올바르지 않습니다.';
      }

      final access = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;

      if (access == null || access.isEmpty) {
        throw '액세스 토큰이 응답에 없습니다.';
      }

      await _storage.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      String msg = _readErrorMessage(e) ?? '로그인에 실패했습니다.';

      if (status == 400 || status == 401) {
        msg = _readErrorMessage(e) ?? '아이디 또는 비밀번호가 올바르지 않습니다.';
      } else if (status == 403) {
        msg = _readErrorMessage(e) ?? '이메일 인증이 완료되지 않았습니다.';
      }

      throw msg;
    } catch (e) {
      throw '로그인 중 오류가 발생했습니다: $e';
    }
  }

  /// 현재 유저 정보 (/api/auth/me)
  Future<Map<String, dynamic>> me() async {
    try {
      final res = await _dio.get('/api/auth/me');

      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }

      throw '내 정보 조회에 실패했습니다. (${res.statusCode})';
    } on DioException catch (e) {
      final msg = _readErrorMessage(e) ?? '내 정보 조회에 실패했습니다.';
      throw msg;
    } catch (e) {
      throw '내 정보 조회 중 오류가 발생했습니다: $e';
    }
  }

  /// 로그아웃
  /// - 서버에 별도 호출 없이, 로컬 토큰만 제거
  Future<void> logout() async {
    await _storage.deleteTokens();
  }

  // ====== 내부 유틸 ======

  String? _readErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg is String && msg.trim().isNotEmpty) {
        return msg.trim();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }
}
