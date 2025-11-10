import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';            // apiBase 정의 (예: http://127.0.0.1:8080)
import '../services/auth_service.dart';

/// /api/auth/findEmail 응답 해석 결과
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
  final AuthService _auth;

  bool loading = false;
  Map<String, dynamic>? profile;
  String? error;

  AuthState(this._auth);

  // ---------------- 공통 유틸 ----------------

  // JSON + (옵션) Authorization 헤더 만들기
  Future<Map<String, String>> _jsonHeaders({bool auth = false}) async {
    final base = {'Content-Type': 'application/json'};
    if (!auth) return base;

    final token = await _auth.getToken();
    if (token != null && token.isNotEmpty) {
      // print('AUTH=Bearer $token'); // 디버그용
      return {...base, 'Authorization': 'Bearer $token'};
    }
    return base;
  }

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
      await _auth.login(username: u, password: p); // 토큰 저장됨
      await loadProfile();                          // 토큰으로 /me 호출
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
      profile = await _auth.me(); // 내부에서 Bearer 포함
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

  Future<FindEmailResult> checkEmailAndFetchUsername(String email) async {
    error = null;
    try {
      final uri = Uri.parse('$apiBase/api/auth/findEmail');
      final res = await http.post(
        uri,
        headers: await _jsonHeaders(), // 공개 엔드포인트
        body: jsonEncode({'email': email.trim()}),
      ).timeout(const Duration(seconds: 10));

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

  // ---------------- 보호된 엔드포인트 예시(게시글) ----------------

  // 내 글 목록 (GET /api/posts/me) — 인증 필요
  Future<List<dynamic>> myPosts() async {
    final uri = Uri.parse('$apiBase/api/posts/me');
    final res = await http.get(uri, headers: await _jsonHeaders(auth: true));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List);
    } else {
      error = _extractMsg(res.body);
      notifyListeners();
      throw Exception('myPosts 실패: ${res.statusCode} $error');
    }
  }

  // 글 작성 (POST /api/posts) — 인증 필요
  Future<bool> createPost({required String title, required String content}) async {
    final uri = Uri.parse('$apiBase/api/posts');
    final res = await http.post(
      uri,
      headers: await _jsonHeaders(auth: true),
      body: jsonEncode({'title': title, 'content': content}),
    );
    if (res.statusCode == 201) {
      return true;
    } else {
      error = _extractMsg(res.body);
      notifyListeners();
      return false;
    }
  }

  // ------------- (옵션) 비밀번호 재설정 2-엔드포인트 -------------
  Future<bool> requestPwResetCode(String username, String email) async {
    error = null; notifyListeners();
    try {
      final uri = Uri.parse('$apiBase/api/auth/pw-reset/request');
      final res = await http.post(
        uri,
        headers: await _jsonHeaders(),
        body: jsonEncode({'username': username.trim(), 'email': email.trim()}),
      ).timeout(const Duration(seconds: 10));

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
    error = null; notifyListeners();
    try {
      final uri = Uri.parse('$apiBase/api/auth/pw-reset/confirm');
      final res = await http.post(
        uri,
        headers: await _jsonHeaders(),
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

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

  // (토큰 방식 미사용 — 인터페이스 유지)
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
