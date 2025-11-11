import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';                // apiBase
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/secure_storage.dart';

/// /api/auth/findEmail 응답 해석 결과
class FindEmailResult {
  final bool exists;        // 가입된 이메일인지
  final String? username;   // 서버에서 받은 아이디(또는 메시지에서 파싱)
  final String message;     // 서버 메시지 (UI에 그대로 표출 가능)

  FindEmailResult({
    required this.exists,
    required this.username,
    required this.message,
  });
}

class AuthState with ChangeNotifier {
  final SecureStorage _storage = SecureStorage();
  late final AuthService _auth;

  bool loading = false;
  Map<String, dynamic>? profile;
  String? error;

  String? _accessToken; // STOMP, API 등에서 쓸 현재 액세스 토큰
  String? _refreshToken;

  AuthState() {
    _auth = AuthService(ApiClient(), _storage);
    _init();
  }

  // ====== getters ======

  bool get isLoggedIn => _accessToken != null;

  String? get accessToken => _accessToken;

  String? get refreshToken => _refreshToken;

  /// 현재 로그인한 유저 아이디 (백엔드 /api/auth/me 응답 기준)
  String? get username {
    final name = profile?['username'] as String?;
    if (name == null) return null;
    final trimmed = name.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // ====== 초기화 ======

  Future<void> _init() async {
    _accessToken = await _storage.readAccessToken();
    _refreshToken = await _storage.readRefreshToken();

    // 이미 토큰이 있으면 프로필 한번 조용히 시도
    if (_accessToken != null) {
      await _loadProfileSilently();
    }

    notifyListeners();
  }

  // ====== 내부 유틸 ======

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
    // 예: "가입된 이메일입니다. (아이디: myUser )"
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

  Future<void> _loadProfileSilently() async {
    try {
      final me = await _auth.me();
      profile = me;
    } catch (e) {
      if (kDebugMode) {
        print('loadProfile silently failed: $e');
      }
      // 여기서는 error 안 건드림
    }
  }

  // ====== 회원가입 / 로그인 / 로그아웃 ======

  Future<void> signup(String u, String e, String p) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _auth.signup(username: u, email: e, password: p);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 일반 로그인
  /// - 성공 시 AuthService가 access/refresh를 SecureStorage에 저장
  /// - 여기서는 메모리 캐시 + 프로필 동기화
  Future<bool> login(String u, String p) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await _auth.login(username: u, password: p);

      _accessToken = await _storage.readAccessToken();
      _refreshToken = await _storage.readRefreshToken();

      await _loadProfileSilently();

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// /api/auth/me를 강제로 다시 불러와 UI 갱신하고 싶을 때
  Future<void> loadProfile() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final me = await _auth.me();
      profile = me;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// OAuth 콜백 등에서 access/refresh를 바로 받는 경우
  /// - OAuthSuccessScreen에서 호출
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
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.logout(); // 내부에서 SecureStorage 삭제 처리
    profile = null;
    _accessToken = null;
    _refreshToken = null;
    error = null;
    loading = false;
    notifyListeners();
  }

  // ====== 아이디 찾기 (이메일 기반) ======

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
        } else {
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

  // ====== 비밀번호 재설정 (기존 HTTP 방식 유지) ======

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

  // 토큰 기반 방식은 현재 사용 안 함 (필요시 구현)
  Future<String?> verifyPwResetCode(
      String username, String email, String code) async {
    return null;
  }

  Future<bool> resetPasswordWithToken({
    required String resetToken,
    required String newPassword,
  }) async {
    return false;
  }
}
