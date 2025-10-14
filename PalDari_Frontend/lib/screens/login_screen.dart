import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final idCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _idFocus = FocusNode();
  final _pwFocus = FocusNode();
  bool _obscurePw = true;

  // Figma 팔레트
  final Color _bgCard = const Color(0xFFFFF7F1);
  final Color _borderColor = const Color(0xFFF29D52);
  final Color _loginFill = const Color(0xCCFAAD55);
  final Color _titlePal = const Color(0xFF734124);
  final Color _titleDari = const Color(0xFF260101);

  @override
  void dispose() {
    idCtrl.dispose();
    pwCtrl.dispose();
    _idFocus.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  InputDecoration _pillFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _bgCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide(color: _borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide(color: _borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide(color: _borderColor, width: 2),
      ),
      labelStyle: const TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontFamily: 'Open Sans',
        fontWeight: FontWeight.w400,
      ),
      errorStyle: const TextStyle(color: Colors.red, height: 0.9),
    );
  }

  String? _validateId(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return '아이디 또는 이메일을 입력해 주세요.';
    if (value.contains('@')) {
      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
      if (!ok) return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  String? _validatePw(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return '비밀번호를 입력해 주세요.';
    if (value.length < 4) return '비밀번호는 4자 이상이어야 합니다.';
    return null;
  }

  Future<void> _submit(AuthState auth) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthState>().login(idCtrl.text, pwCtrl.text);
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final media = MediaQuery.of(context);
    final viewWidth = media.size.width;
    final scale = (viewWidth / 411).clamp(0.9, 1.1);

    // 내부(카드 안) 패딩
    final hPad = 24 * scale;
    final vPad = 28 * scale;

    // 화면 바깥 여백(카드와 화면 가장자리 사이 간격)
    final outerHPad = 20 * scale;

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 카드의 최대 너비 제한 (폰에서는 꽉 차지 않도록)
          double maxCardWidth =
          (constraints.maxWidth - outerHPad * 2).clamp(320.0, 420.0);

          return Container(
            width: double.infinity,
            color: const Color(0xFFFFF7F1),
            child: SafeArea(
              child: SingleChildScrollView(
                // 화면 바깥 여백
                padding: EdgeInsets.symmetric(
                  horizontal: outerHPad,
                  vertical: outerHPad,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxCardWidth,
                    // 뷰포트 높이만큼 최소 확보(세로 중앙 정렬 + 오버플로우 방지)
                    minHeight: constraints.maxHeight - (outerHPad * 2),
                  ),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding:
                      EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                      decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Pal다리 로고
                          Center(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Pal',
                                    style: TextStyle(
                                      color: _titlePal,
                                      fontSize: 48 * scale,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '다리',
                                    style: TextStyle(
                                      color: _titleDari,
                                      fontSize: 48 * scale,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 로고 아래 여백
                          SizedBox(height: 56 * scale),

                          // 폼
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: idCtrl,
                                  focusNode: _idFocus,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration:
                                  _pillFieldDecoration('아이디 또는 이메일'),
                                  validator: _validateId,
                                  onFieldSubmitted: (_) =>
                                      _pwFocus.requestFocus(),
                                ),
                                SizedBox(height: 16 * scale),
                                TextFormField(
                                  controller: pwCtrl,
                                  focusNode: _pwFocus,
                                  textInputAction: TextInputAction.done,
                                  obscureText: _obscurePw,
                                  decoration:
                                  _pillFieldDecoration('비밀번호').copyWith(
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePw
                                          ? '비밀번호 표시'
                                          : '비밀번호 숨기기',
                                      icon: Icon(
                                        _obscurePw
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.black54,
                                      ),
                                      onPressed: () => setState(
                                              () => _obscurePw = !_obscurePw),
                                    ),
                                  ),
                                  validator: _validatePw,
                                  onFieldSubmitted: (_) => _submit(auth),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14 * scale),

                          if (auth.error != null) ...[
                            Text(
                              auth.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            SizedBox(height: 8 * scale),
                          ],

                          // 로그인 버튼 (살짝 낮춤)
                          SizedBox(
                            height: 50 * scale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _loginFill,
                                borderRadius: BorderRadius.circular(100),
                                border:
                                Border.all(color: _borderColor, width: 1),
                              ),
                              child: TextButton(
                                onPressed:
                                auth.loading ? null : () => _submit(auth),
                                child: auth.loading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  '로그인',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: 'Open Sans',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 14 * scale),

                          // 링크들
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/find-id'),
                                child: const Text('아이디 찾기'),
                              ),
                              const Text('·'),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/reset-password'),
                                child: const Text('비밀번호 재설정'),
                              ),
                              const Text('·'),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/signup'),
                                child: const Text('회원가입'),
                              ),
                            ],
                          ),
                          SizedBox(height: 14 * scale),

                          // 또는
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: Color(0xFF260101),
                                  thickness: 1,
                                ),
                              ),
                              SizedBox(width: 12 * scale),
                              const Text(
                                '또는',
                                style: TextStyle(
                                  color: Color(0xFF260101),
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              SizedBox(width: 12 * scale),
                              const Expanded(
                                child: Divider(
                                  color: Color(0xFF260101),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14 * scale),

                          // Google 로그인
                          Center(
                            child: Column(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(48),
                                  onTap: () async {
                                    await launchUrl(
                                      Uri.parse(oauthGoogleUrl),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  child: Container(
                                    width: 50 * scale,
                                    height: 50 * scale,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        width: 1,
                                        color: Colors.black.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.g_mobiledata,
                                      size: 40 * scale,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 2 * scale),
                                const Text(
                                  'Google',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: 'Open Sans',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 하단 여백 0 → overflow 방지
                          const SizedBox(height: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
