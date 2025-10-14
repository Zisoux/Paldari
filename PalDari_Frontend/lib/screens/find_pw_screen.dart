import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class FindPwScreen extends StatefulWidget {
  const FindPwScreen({super.key});

  @override
  State<FindPwScreen> createState() => _FindPwScreenState();
}

class _FindPwScreenState extends State<FindPwScreen> {
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final newPwCtrl = TextEditingController();

  final _usernameKey = GlobalKey<FormFieldState<String>>();
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final _codeKey = GlobalKey<FormFieldState<String>>();
  final _pwKey = GlobalKey<FormFieldState<String>>();

  bool _requesting = false;
  bool _confirming = false;
  bool _showCodeSection = false; // ✅ 인증요청 성공 시 노출

  // 색상 팔레트
  final Color _pageBg = const Color(0xFFFFF7F1);
  final Color _cardBg = const Color(0xFFFFF7F1);
  final Color _border = const Color(0xFFF29D52);

  @override
  void dispose() {
    usernameCtrl.dispose();
    emailCtrl.dispose();
    codeCtrl.dispose();
    newPwCtrl.dispose();
    super.dispose();
  }

  // ---------------- 유효성 검사 ----------------
  String? _validateUsername(String? v) {
    if ((v ?? '').trim().isEmpty) return '아이디를 입력해 주세요.';
    return null;
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '이메일 주소를 입력해 주세요.';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(s)) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  String? _validateCode(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '인증 코드를 입력해 주세요.';
    if (s.length < 4) return '인증 코드는 4자 이상입니다.';
    return null;
  }

  String? _validatePw(String? v) {
    final s = (v ?? '').trim();
    if (s.length < 6) return '비밀번호는 6자 이상입니다.';
    return null;
  }

  // ---------------- 스타일 ----------------
  InputDecoration _rectField(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: _border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: _border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: _border, width: 2),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF260101),
        fontSize: 15,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
      ),
      suffixIcon: suffix,
    );
  }

  // ---------------- 동작 ----------------
  Future<void> _onRequestCode() async {
    final uOk = _usernameKey.currentState?.validate() ?? false;
    final eOk = _emailKey.currentState?.validate() ?? false;
    if (!uOk || !eOk) return;

    setState(() => _requesting = true);
    final auth = context.read<AuthState>();
    final ok = await auth.requestPwResetCode(
      usernameCtrl.text.trim(),
      emailCtrl.text.trim(),
    );
    setState(() => _requesting = false);

    if (!mounted) return;
    if (ok) {
      setState(() => _showCodeSection = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드를 이메일로 보냈습니다.')),
      );
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  Future<void> _onConfirm() async {
    final eOk = _emailKey.currentState?.validate() ?? false;
    final cOk = _codeKey.currentState?.validate() ?? false;
    final pOk = _pwKey.currentState?.validate() ?? false;
    if (!eOk || !cOk || !pOk) return;

    setState(() => _confirming = true);
    final auth = context.read<AuthState>();
    final ok = await auth.resetPasswordWithCode(
      username: usernameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      code: codeCtrl.text.trim(),
      newPassword: newPwCtrl.text.trim(),
    );
    setState(() => _confirming = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('비밀번호가 변경되었습니다.')));
      Navigator.pop(context);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 411).clamp(0.9, 1.1);

    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 찾기')),
      body: Container(
        width: double.infinity,
        color: _pageBg,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20 * scale),
            child: ConstrainedBox(
              constraints:
              BoxConstraints(maxWidth: (width - 40).clamp(320, 420)),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 20 * scale, vertical: 24 * scale),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ✅ 타이틀 복구
                    Text(
                      '비밀번호 재설정',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28 * scale,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 20 * scale),

                    TextFormField(
                      key: _usernameKey,
                      controller: usernameCtrl,
                      decoration: _rectField('아이디'),
                      validator: _validateUsername,
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: 12 * scale),
                    TextFormField(
                      key: _emailKey,
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _rectField(
                        '이메일 주소',
                        suffix: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _requesting
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                            CircularProgressIndicator(strokeWidth: 2),
                          )
                              : TextButton(
                            onPressed: _onRequestCode,
                            child: const Text('인증요청'),
                          ),
                        ),
                      ),
                      validator: _validateEmail,
                      onFieldSubmitted: (_) => _onRequestCode(),
                    ),

                    // ✅ 인증 요청 후에만 표시되는 구간
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          SizeTransition(
                            sizeFactor: anim,
                            axisAlignment: -1.0,
                            child: child,
                          ),
                      child: _showCodeSection
                          ? Column(
                        key: const ValueKey('code-section'),
                        children: [
                          SizedBox(height: 16 * scale),
                          TextFormField(
                            key: _codeKey,
                            controller: codeCtrl,
                            decoration: _rectField('이메일 인증 코드'),
                            validator: _validateCode,
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: 12 * scale),
                          TextFormField(
                            key: _pwKey,
                            controller: newPwCtrl,
                            obscureText: true,
                            decoration: _rectField('새 비밀번호'),
                            validator: _validatePw,
                            onFieldSubmitted: (_) => _onConfirm(),
                          ),
                          SizedBox(height: 20 * scale),
                          SizedBox(
                            height: 50 * scale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _border,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextButton(
                                onPressed: _confirming ? null : _onConfirm,
                                child: _confirming
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                    AlwaysStoppedAnimation(
                                        Colors.white),
                                  ),
                                )
                                    : const Text(
                                  '비밀번호 변경',
                                  style: TextStyle(
                                    color: Color(0xFFFFF7F1),
                                    fontSize: 15,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
