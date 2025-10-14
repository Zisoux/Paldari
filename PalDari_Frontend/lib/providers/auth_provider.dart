import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';            // ✅ apiBase 정의 (예: http://10.0.2.2:8080)
import '../services/auth_service.dart';

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
  final AuthService _auth;

  bool loading = false;
  Map<String, dynamic>? profile;
  String? error;

  AuthState(this._auth);

  // ---------------- 공통 유틸 ----------------

  String _extractMsg(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      final raw = (m['message'] ?? m['error'] ?? '').toString();
      return raw.trim();
    } catch (_) {
      // 서버가 text/plain을 줄 수도 있으므로 body 자체를 사용
      return body.trim();
    }
  }

  String? _parseUsernameFromMessage(String msg) {
    // 예: "가입된 이메일입니다. (아이디: myUser )"
    final key = '아이디';
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

  // ---------------- 인증 기본 흐름 ----------------

  Future<void> signup(String u, String e, String p) async {
    loading = true; error = null; notifyListeners();
    try {
      await _auth.signup(username: u, email: e, password: p);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<bool> login(String u, String p) async {
    loading = true; error = null; notifyListeners();
    try {
      await _auth.login(username: u, password: p);
      await loadProfile();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    loading = true; error = null; notifyListeners();
    try {
      profile = await _auth.me();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> setTokenFromCallback(String token) async {
    await _auth.saveTokenFromCallback(token);
    await loadProfile();
  }

  Future<void> logout() async {
    await _auth.logout();
    profile = null;
    notifyListeners();
  }

  // ---------------- 아이디 찾기(이메일로 확인) ----------------

  /// 백엔드: POST /api/auth/findEmail { email }
  /// - 권장: 200 OK + {exists, username, message}
  /// - 레거시: 400 + "가입된 이메일입니다. (아이디: xxx )"
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
        // JSON 응답(권장)
        try {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          exists = (data['exists'] as bool?) ?? false;
          username = (data['username'] as String?) ??
              (data['usernameMasked'] as String?);
        } catch (_) {
          // 파싱 실패 시 메시지 기반 폴백
          if (msg.contains('가입된 이메일')) {
            exists = true;
            username = _parseUsernameFromMessage(msg);
          } else if (msg.contains('등록되지 않은 이메일')) {
            exists = false;
          }
        }
      } else {
        // 레거시(400) 메시지 기반
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

  /// 존재 여부만 필요할 때
  Future<bool> checkEmailExists(String email) async {
    final res = await checkEmailAndFetchUsername(email);
    return res.exists;
  }

  // ---------------- 비밀번호 재설정 (2-엔드포인트 버전) ----------------
  // POST /api/auth/pw-reset/request  {username, email}
  // POST /api/auth/pw-reset/confirm  {username, email, code, newPassword}

  /// 1) 인증코드 요청
  Future<bool> requestPwResetCode(String username, String email) async {
    error = null; notifyListeners();
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

  /// 2) 코드 + 새 비번으로 즉시 변경
  Future<bool> resetPasswordWithCode({
    required String username,
    required String email,
    required String code,
    required String newPassword,
  }) async {
    error = null; notifyListeners();
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

  // (토큰 방식 미사용 — 유지하고 싶으면 남겨두고, 아니면 삭제해도 됨)
  Future<String?> verifyPwResetCode(String username, String email, String code) async {
    return null;
  }

  Future<bool> resetPasswordWithToken({
    required String resetToken,
    required String newPassword,
  }) async {
    return false;
  }
}
