// lib/providers/auth_provider.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/secure_storage.dart';

class FindEmailResult {
  final bool exists;
  final String? username;
  final String message;

  FindEmailResult({
    required this.exists,
    required this.username,
    required this.message,
  });
}

class AuthState with ChangeNotifier {
  final SecureStorage _storage = SecureStorage();
  late final ApiClient _api;
  late final AuthService _auth;

  bool loading = false;
  String? error;

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? profile;

  // ===== 환경설정 값 =====
  bool allowNotification = true;
  bool allowMatching = true;
  bool realtimeTranslation = false;

  // ===== 태그 / 지역 / 구사 언어 =====
  List<String>? _tags;
  List<String>? _regions;
  List<String>? _languages; // 프로필 basic의 구사 언어 (배열)

  List<String> get tags => _tags ?? const <String>[];
  List<String> get regions => _regions ?? const <String>[];
  List<String> get languages => _languages ?? const <String>[];

  // ===== 생성자 =====
  AuthState() {
    _api = ApiClient();
    _auth = AuthService(_api, _storage);
    _init();
  }

  // ===== 공용 getter =====

  bool get isLoggedIn =>
      _accessToken != null && _accessToken!.isNotEmpty;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  String? get username {
    final name = profile?['username'] as String?;
    if (name == null) return null;
    final t = name.trim();
    return t.isEmpty ? null : t;
  }

  /// (추가) 어디서든 액세스 토큰을 얻고 싶을 때 호출
  /// 메모리에 없으면 SecureStorage에서 읽어와 메모리에 적재
  Future<String?> pickAccessToken() async {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      return _accessToken;
    }
    final t = await _storage.readAccessToken();
    if (t != null && t.isNotEmpty) {
      _accessToken = t;
    }
    return _accessToken;
  }

  /// (추가, 선택) Authorization 헤더를 한 번에 만들고 싶을 때
  Future<Map<String, String>> buildAuthHeader() async {
    final t = await pickAccessToken();
    if (t == null || t.isEmpty) return const {};
    return {'Authorization': 'Bearer $t'};
  }

  // ===== 초기화 =====

  Future<void> _init() async {
    _accessToken = await _storage.readAccessToken();
    _refreshToken = await _storage.readRefreshToken();

    if (isLoggedIn) {
      await _loadProfileSilently();

      // me()에서 401 이었으면 여기서 isLoggedIn=false 가 되어 있음
      if (isLoggedIn) {
        await reloadSettings(silent: true);
        await reloadTags(silent: true);
        await reloadRegions(silent: true);
        // _languages는 /api/profile/basic 응답(profile)에 포함된 걸 사용
      }
    }

    notifyListeners();
  }

  // ===== 내부 유틸 =====

  String _extractMsg(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      final raw = (m['message'] ?? m['error'] ?? '').toString();
      return raw.trim();
    } catch (_) {
      return body.trim();
    }
  }

  String? _parseUsernameFromMessage(String msg) {
    const key = '아이디';
    final idxKey = msg.indexOf(key);
    if (idxKey < 0) return null;
    final idxColon = msg.indexOf(':', idxKey);
    if (idxColon < 0) return null;
    final idxClose = msg.indexOf(')', idxColon + 1);

    final raw = (idxClose > idxColon)
        ? msg.substring(idxColon + 1, idxClose)
        : msg.substring(idxColon + 1);

    final u = raw.trim();
    return u.isEmpty ? null : u;
  }

  Future<void> _clearAuthSilently() async {
    await _storage.deleteTokens();
    _accessToken = null;
    _refreshToken = null;
    profile = null;
    _tags = const <String>[];
    _regions = const <String>[];
    _languages = const <String>[];
    // 환경 설정은 디폴트로 초기화
    allowNotification = true;
    allowMatching = true;
    realtimeTranslation = false;
  }

  Future<void> _loadProfileSilently() async {
    try {
      final p = await _auth.me();
      if (kDebugMode) {
        print('me() = $p');
      }
      profile = p;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
        // 토큰 무효 → 조용히 정리
        await _clearAuthSilently();
      } else if (kDebugMode) {
        print('loadProfile silently failed: $e');
      }
    } catch (e) {
      // 여기서도 굳이 UNAUTHORIZED 찍고 싶지 않으면 주석 처리 가능
      if (kDebugMode && e.toString() != 'UNAUTHORIZED') {
        print('loadProfile silently failed: $e');
      }
    }
  }

  // ===== 회원가입 / 로그인 / 로그아웃 =====

  Future<void> signup(
      String u,
      String e,
      String p, {
        String? gender,      // ✅ 성별
        String? birthdate,   // ✅ 생년월일
        List<String>? countries,     // ✅ 복수로 변경
      }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _auth.signup(
        username: u,
        email: e,
        password: p,
        gender: gender,
        birthdate: birthdate,
        countries: countries,      // ✅ 그대로 전달
    );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String u, String p) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _auth.login(username: u, password: p);

      _accessToken = await _storage.readAccessToken();
      _refreshToken = await _storage.readRefreshToken();

      await _loadProfileSilently();

      if (isLoggedIn) {
        await reloadSettings(silent: true);
        await reloadTags(silent: true);
        await reloadRegions(silent: true);
      }

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      profile = await _auth.me();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setTokensFromCallback({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    await _loadProfileSilently();
    if (isLoggedIn) {
      await reloadSettings(silent: true);
      await reloadTags(silent: true);
      await reloadRegions(silent: true);
    }

    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.logout();
    await _clearAuthSilently();
    loading = false;
    error = null;
    notifyListeners();
  }

  // ===== 아이디 찾기 =====

  Future<FindEmailResult> checkEmailAndFetchUsername(String email) async {
    error = null;
    try {
      final uri = Uri.parse('$apiBase/api/auth/findEmail');
      final res = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      )
          .timeout(const Duration(seconds: 10));

      final msg = _extractMsg(res.body);
      bool exists = false;
      String? username;

      if (res.statusCode == 200) {
        try {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          exists = (data['exists'] as bool?) ?? false;
          username = (data['username'] as String?) ??
              (data['usernameMasked'] as String?);
        } catch (_) {
          if (msg.contains('가입된 이메일')) {
            exists = true;
            username = _parseUsernameFromMessage(msg);
          } else if (msg.contains('등록되지 않은 이메일')) {
            exists = false;
          }
        }
      } else {
        if (msg.contains('가입된 이메일')) {
          exists = true;
          username = _parseUsernameFromMessage(msg);
        } else if (msg.contains('등록되지 않은 이메일')) {
          exists = false;
        }
      }

      if (res.statusCode >= 400 &&
          msg.isNotEmpty &&
          !msg.contains('가입된 이메일')) {
        error = msg;
      }

      notifyListeners();
      return FindEmailResult(
        exists: exists,
        username: username,
        message: msg.isNotEmpty
            ? msg
            : (exists
            ? '가입된 이메일입니다. (아이디: ${username ?? ''})'
            : '등록되지 않은 이메일입니다.'),
      );
    } catch (e) {
      error = '네트워크 오류: $e';
      notifyListeners();
      return FindEmailResult(
        exists: false,
        username: null,
        message: error!,
      );
    }
  }

  Future<bool> checkEmailExists(String email) async {
    final res = await checkEmailAndFetchUsername(email);
    return res.exists;
  }

  // ===== 비번 재설정 (HTTP) =====

  Future<bool> requestPwResetCode(String username, String email) async {
    error = null;
    notifyListeners();
    try {
      final uri = Uri.parse('$apiBase/api/auth/pw-reset/request');
      final res = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim(),
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return true;
      } else {
        error = _extractMsg(res.body);
        return false;
      }
    } catch (e) {
      error = '네트워크 오류: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> resetPasswordWithCode({
    required String username,
    required String email,
    required String code,
    required String newPassword,
  }) async {
    error = null;
    notifyListeners();
    try {
      final uri = Uri.parse('$apiBase/api/auth/pw-reset/confirm');
      final res = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword.trim(),
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return true;
      } else {
        error = _extractMsg(res.body);
        return false;
      }
    } catch (e) {
      error = '네트워크 오류: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }

  // 필요 없으면 지워도 되는 placeholder
  Future<String?> verifyPwResetCode(
      String username, String email, String code) async =>
      null;

  Future<bool> resetPasswordWithToken({
    required String resetToken,
    required String newPassword,
  }) async =>
      false;

  // ===== 회원탈퇴 =====

  Future<bool> withdrawAccount() async {
    try {
      // 1) 백엔드 회원탈퇴 API 호출
      final res = await _api.dio.delete('/api/profile');

      if (res.statusCode == 204 || res.statusCode == 200) {
        // 2) 로컬 토큰/상태 삭제
        await _clearAuthSilently();
        notifyListeners();
        return true;
      } else {
        error = '회원탈퇴 실패: ${res.statusMessage}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      error = '회원탈퇴 오류: $e';
      notifyListeners();
      return false;
    }
  }

  // ===== Settings (/api/profile/settings) =====

  Future<void> reloadSettings({bool silent = false}) async {
    if (!isLoggedIn) {
      if (!silent) notifyListeners();
      return;
    }
    try {
      final res = await _api.dio.get('/api/profile/settings');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        allowNotification =
            (data['allowNotification'] as bool?) ?? allowNotification;
        allowMatching =
            (data['allowMatching'] as bool?) ?? allowMatching;
        realtimeTranslation =
            (data['realtimeTranslation'] as bool?) ??
                realtimeTranslation;
      }
      if (!silent) notifyListeners();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (kDebugMode && !silent) {
          print('reloadSettings unauthorized (ignored)');
        }
      } else {
        debugPrint('reloadSettings failed: $e');
      }
      if (!silent) notifyListeners();
    } catch (e) {
      debugPrint('reloadSettings failed: $e');
      if (!silent) notifyListeners();
    }
  }

  Future<void> updateSettings({
    bool? allowNotification,
    bool? allowMatching,
    bool? realtimeTranslation,
  }) async {
    if (!isLoggedIn) return;
    try {
      final payload = <String, dynamic>{};
      if (allowNotification != null) {
        payload['allowNotification'] = allowNotification;
      }
      if (allowMatching != null) {
        payload['allowMatching'] = allowMatching;
      }
      if (realtimeTranslation != null) {
        payload['realtimeTranslation'] = realtimeTranslation;
      }
      if (payload.isEmpty) return;

      final res =
      await _api.dio.patch('/api/profile/settings', data: payload);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        this.allowNotification =
            (data['allowNotification'] as bool?) ??
                this.allowNotification;
        this.allowMatching =
            (data['allowMatching'] as bool?) ??
                this.allowMatching;
        this.realtimeTranslation =
            (data['realtimeTranslation'] as bool?) ??
                this.realtimeTranslation;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('updateSettings failed: $e');
    }
  }

  // ===== Profile Basic (gender, birthdate, country, livingIn, introduction, tags, languages, regions) =====

  Future<Map<String, dynamic>?> fetchProfileBasic() async {
    if (!isLoggedIn) return null;
    try {
      final res = await _api.dio.get('/api/profile/basic');
      if (res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;

        // 전체 profile에도 병합해두면 앱 전반에서 동일하게 참조 가능
        profile = {...?profile, ...data};

        // languages 필드가 있다면 _languages에 캐시
        final langs = data['languages'];
        if (langs is List) {
          _languages =
              langs.map((e) => e.toString()).toList();
        } else if (langs is String) {
          _languages =
              langs.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }

        notifyListeners();
        return data;
      }
    } catch (e) {
      debugPrint('fetchProfileBasic failed: $e');
    }
    return null;
  }

  Future<bool> updateProfileBasic({
    String? gender,
    DateTime? birthdate,
    List<String>? countries,  // ✅ 국적 코드 리스트 (예: ["KR","MY"])
    String? livingIn,
    String? introduction,
    List<String>? tags,
    List<String>? languages,  // ✅ 구사 언어 (복수)
    List<String>? regions,
  }) async {
    if (!isLoggedIn) return false;

    final payload = <String, dynamic>{};
    if (gender != null) payload['gender'] = gender;
    if (birthdate != null) {
      final y = birthdate.year.toString().padLeft(4, '0');
      final m = birthdate.month.toString().padLeft(2, '0');
      final d = birthdate.day.toString().padLeft(2, '0');
      payload['birthdate'] = '$y-$m-$d';
    }
   if (countries != null) payload['countries'] = countries; // ✅ 국적 리스트 전달
    if (livingIn != null) payload['livingIn'] = livingIn;
    if (introduction != null) payload['introduction'] = introduction;

    // 🔹 태그 / 구사 언어 / 지역
    if (tags != null) payload['tags'] = tags;
    if (languages != null) payload['languages'] = languages;
    if (regions != null) payload['regions'] = regions;

    if (payload.isEmpty) return true;

    try {
      final res =
      await _api.dio.patch('/api/profile/basic', data: payload);
      if (res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;

        // 성공 시 로컬 캐시 갱신
        profile = {...?profile, ...data};

        // 응답에 languages가 있으면 _languages 업데이트
        final langs = data['languages'];
        if (langs is List) {
          _languages =
              langs.map((e) => e.toString()).toList();
        } else if (langs is String) {
          _languages =
              langs.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }

        notifyListeners();
        return true;
      }
      return true; // 204 No Content 같은 경우
    } catch (e) {
      debugPrint('updateProfileBasic failed: $e');
      return false;
    }
  }

  // ===== Tags =====

  Future<void> reloadTags({bool silent = false}) async {
    if (!isLoggedIn) {
      _tags = const <String>[];
      if (!silent) notifyListeners();
      return;
    }
    try {
      final res = await _api.dio.get('/api/profile/tags');
      final data = res.data;

      // 🔥 항상 List<String>으로 강제 캐스팅
      if (data is Map && data['items'] is List) {
        _tags = (data['items'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (data is List) {
        _tags = (data as List)
            .map((e) => e.toString())
            .toList();
      } else {
        _tags = const <String>[];
      }

      if (!silent) notifyListeners();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (kDebugMode && !silent) {
          print('reloadTags unauthorized (ignored)');
        }
      } else {
        debugPrint('reloadTags failed: $e');
      }
      _tags = _tags ?? const <String>[];
      if (!silent) notifyListeners();
    } catch (e) {
      debugPrint('reloadTags failed: $e');
      _tags = _tags ?? const <String>[];
      if (!silent) notifyListeners();
    }
  }

  Future<void> addTag(String tag) async {
    if (!isLoggedIn) return;
    final t = tag.trim();
    if (t.isEmpty) return;
    try {
      final res = await _api.dio.post(
        '/api/profile/tags',
        data: {'tag': t},
      );
      final data = res.data;
      if (data is Map && data['items'] is List) {
        _tags = (data['items'] as List)
            .map((e) => e.toString())
            .toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('addTag failed: $e');
    }
  }

  Future<void> removeTag(String tag) async {
    if (!isLoggedIn) return;
    try {
      final res = await _api.dio.delete(
        '/api/profile/tags',
        data: {'tag': tag},
      );
      final data = res.data;
      if (data is Map && data['items'] is List) {
        _tags = (data['items'] as List)
            .map((e) => e.toString())
            .toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('removeTag failed: $e');
    }
  }

  // ===== Regions =====

  Future<void> reloadRegions({bool silent = false}) async {
    if (!isLoggedIn) {
      _regions = const <String>[];
      if (!silent) notifyListeners();
      return;
    }
    try {
      final res = await _api.dio.get('/api/profile/regions');
      final data = res.data;

      // 🔥 항상 List<String>으로 강제 캐스팅
      if (data is Map && data['items'] is List) {
        _regions = (data['items'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (data is List) {
        _regions = (data as List)
            .map((e) => e.toString())
            .toList();
      } else {
        _regions = const <String>[];
      }

      if (!silent) notifyListeners();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (kDebugMode && !silent) {
          print('reloadRegions unauthorized (ignored)');
        }
      } else {
        debugPrint('reloadRegions failed: $e');
      }
      _regions = _regions ?? const <String>[];
      if (!silent) notifyListeners();
    } catch (e) {
      debugPrint('reloadRegions failed: $e');
      _regions = _regions ?? const <String>[];
      if (!silent) notifyListeners();
    }
  }

  Future<void> addRegion(String region) async {
    if (!isLoggedIn) return;
    final r = region.trim();
    if (r.isEmpty) return;
    try {
      final res = await _api.dio.post(
        '/api/profile/regions',
        data: {'region': r},
      );
      final data = res.data;
      if (data is Map && data['items'] is List) {
        _regions = (data['items'] as List)
            .map((e) => e.toString())
            .toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('addRegion failed: $e');
    }
  }

  Future<void> removeRegion(String region) async {
    if (!isLoggedIn) return;
    try {
      final res = await _api.dio.delete(
        '/api/profile/regions',
        data: {'region': region},
      );
      final data = res.data;
      if (data is Map && data['items'] is List) {
        _regions = (data['items'] as List)
            .map((e) => e.toString())
            .toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('removeRegion failed: $e');
    }
  }
}
