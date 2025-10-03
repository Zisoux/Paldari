import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthState with ChangeNotifier {
  final AuthService _auth;
  bool loading = false;
  Map<String, dynamic>? profile;
  String? error;

  AuthState(this._auth);

  Future<void> signup(String u, String e, String p) async {
    loading = true; error = null; notifyListeners();
    try { await _auth.signup(username: u, email: e, password: p); }
    catch (e) { error = e.toString(); }
    finally { loading = false; notifyListeners(); }
  }

  Future<bool> login(String u, String p) async {
    loading = true; error = null; notifyListeners();
    try { await _auth.login(username: u, password: p); await loadProfile(); return true; }
    catch (e) { error = e.toString(); return false; }
    finally { loading = false; notifyListeners(); }
  }

  Future<void> loadProfile() async {
    loading = true; error = null; notifyListeners();
    try { profile = await _auth.me(); }
    catch (e) { error = e.toString(); }
    finally { loading = false; notifyListeners(); }
  }

  Future<void> setTokenFromCallback(String token) async {
    await _auth.saveTokenFromCallback(token);
    await loadProfile();
  }

  Future<void> logout() async {
    await _auth.logout(); profile = null; notifyListeners();
  }
}
