import 'package:dio/dio.dart';
import 'api_client.dart';
import 'secure_storage.dart';

class AuthService {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthService(this._api, this._storage);

  Dio get _dio => _api.dio;

  // ================= 회원가입 =================

  Future<void> signup({
    required String username,
    required String email,
    required String password,
    String? gender,      // ✅ 선택
    String? birthdate,   // ✅ 선택 (yyyy-MM-dd 문자열)
    List<String>? countries,     // ✅ 추가: 국가 코드 (예: "KR", "MY")
  }) async {
    try {
      final body = <String, dynamic>{
        'username': username,
        'email': email,
        'password': password,
      };

      if (gender != null && gender.isNotEmpty) {
        body['gender'] = gender;
      }
      if (birthdate != null && birthdate.isNotEmpty) {
        body['birthdate'] = birthdate;
      }
      if (countries != null && countries.isNotEmpty) {
        body['countries'] = countries;
      }

      final res = await _dio.post(
        '/api/auth/signup',
        data: body,
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

  // ================= 로그인 (access + refresh 저장) =================

  /// 성공 시 accessToken / refreshToken 을 SecureStorage에 저장
  /// 실패 시 사람이 읽을 수 있는 메시지 throw
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

  // ================= 토큰/프로필 =================

  /// 현재 저장된 Access Token
  Future<String?> getAccessToken() async {
    return _storage.readAccessToken();
  }

  /// 현재 저장된 Refresh Token
  Future<String?> getRefreshToken() async {
    return _storage.readRefreshToken();
  }

  /// OAuth2 성공 리다이렉트에서 받은 토큰 저장용
  /// - /oauth-success?access=...&refresh=... 이런 식으로 받는 것을 상정
  Future<void> saveTokenFromCallback({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  /// /api/auth/me
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

  // ================= 로그아웃 =================

  /// 서버 호출 없이 로컬 토큰만 제거
  Future<void> logout() async {
    await _storage.deleteTokens();
  }

  // ================= 내부 유틸 =================

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

  /// 내 환경설정 조회
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final res = await _dio.get('/api/user/settings');
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      throw '설정 조회 실패 (${res.statusCode})';
    } on DioException catch (e) {
      throw _readErrorMessage(e) ?? '설정 조회 실패';
    }
  }

  /// 환경설정 업데이트 (부분 업데이트 가능)
  Future<Map<String, dynamic>> updateSettings({
    bool? allowNotification,
    bool? allowMatching,
    bool? realtimeTranslation,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (allowNotification != null) body['allowNotification'] = allowNotification;
      if (allowMatching != null) body['allowMatching'] = allowMatching;
      if (realtimeTranslation != null) body['realtimeTranslation'] = realtimeTranslation;

      final res = await _dio.patch('/api/user/settings', data: body);
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      throw '설정 변경 실패 (${res.statusCode})';
    } on DioException catch (e) {
      throw _readErrorMessage(e) ?? '설정 변경 실패';
    }
  }

  // ===== Tags =====

  Future<List<String>> getTags() async {
    try {
      final res = await _dio.get('/api/user/tags');
      if (res.statusCode == 200 && res.data is Map) {
        final items = (res.data['items'] as List?) ?? [];
        return items.map((e) => e.toString()).toList();
      }
      throw '태그 조회 실패 (${res.statusCode})';
    } on DioException catch (e) {
      throw _readErrorMessage(e) ?? '태그 조회 실패';
    }
  }

  Future<List<String>> addTag(String tag) async {
    try {
      final res = await _dio.post('/api/user/tags', data: {'tag': tag});
      if (res.statusCode == 200 && res.data is Map) {
        final items = (res.data['items'] as List?) ?? [];
        return items.map((e) => e.toString()).toList();
      }
      throw '태그 추가 실패 (${res.statusCode})';
    } on DioException catch (e) {
      throw _readErrorMessage(e) ?? '태그 추가 실패';
    }
  }

  Future<List<String>> removeTag(String tag) async {
    try {
      final res = await _dio.delete('/api/user/tags', data: {'tag': tag});
      if (res.statusCode == 200 && res.data is Map) {
        final items = (res.data['items'] as List?) ?? [];
        return items.map((e) => e.toString()).toList();
      }
      throw '태그 삭제 실패 (${res.statusCode})';
    } on DioException catch (e) {
      throw _readErrorMessage(e) ?? '태그 삭제 실패';
    }
  }

  // ===== Regions =====

  Future<List<String>> getRegions() async {
    try {
      final res = await _dio.get('/api/user/regions');
      if (res.statusCode == 200 && res.data is Map) {
        final items = (res.data['items'] as List?) ?? [];
        return items.map((e) => e.toString()).toList();
      }
      throw '지역 조회 실패 (${res.statusCode})';
    } on DioException catch (e) {
      throw _readErrorMessage(e) ?? '지역 조회 실패';
    }
  }

  Future<List<String>> addRegion(String region) async {
    try {
      final res = await _dio.post('/api/user/regions', data: {'region': region});
      if (res.statusCode == 200 && res.data is Map) {
        final items = (res.data['items'] as List?) ?? [];
        return items.map((e) => e.toString()).toList();
      }
      throw '지역 추가 실패 (${res.statusCode})';
    } on DioException catch (e) {
      throw _readErrorMessage(e) ?? '지역 추가 실패';
    }
  }

  Future<List<String>> removeRegion(String region) async {
    try {
      final res = await _dio.delete('/api/user/regions', data: {'region': region});
      if (res.statusCode == 200 && res.data is Map) {
        final items = (res.data['items'] as List?) ?? [];
        return items.map((e) => e.toString()).toList();
      }
      throw '지역 삭제 실패 (${res.statusCode})';
    } on DioException catch (e) {
      throw _readErrorMessage(e) ?? '지역 삭제 실패';
    }
  }

}
