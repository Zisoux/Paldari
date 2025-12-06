// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final idCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final pwConfirmCtrl = TextEditingController();
  final ageCtrl = TextEditingController(); // 생년월일 입력용 (YYYY-MM-DD)

  final _formKey = GlobalKey<FormState>();
  final _idFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _pwFocus = FocusNode();
  final _pw2Focus = FocusNode();

  String _gender = '선택 안함';
  String? _countryCode; // ✅ 국적 코드 (예: "KR")
  bool _obscurePw = true;
  bool _obscurePw2 = true;

  // Figma 스타일 팔레트
  final Color _pageBg = const Color(0xFFFFF7F1);    // 전체 배경
  final Color _cardBg = const Color(0xFFFFF7F1);    // 카드 내부(피그마 동일 톤)
  final Color _border = const Color(0xFFF29D52);    // 오렌지 보더/버튼
  final Color _title = const Color(0xFF260101);     // 타이틀 컬러
  final Color _btnFg = const Color(0xFFFFF7F1);     // 버튼 글자색(밝은톤)

  /// 회원가입용 국가 코드 목록 (홈 화면에서 country와 동일 기준)
  static const Map<String, String> _countryOptions = {
    'KR': '대한민국',
    'JP': '일본',
    'AU': '호주',
    'MY': '말레이시아',
    'US': '미국',
    'CA': '캐나다',
    'UK': '영국',
    'DE': '독일',
    'FR': '프랑스',
  };

  @override
  void dispose() {
    idCtrl.dispose();
    emailCtrl.dispose();
    pwCtrl.dispose();
    pwConfirmCtrl.dispose();
    ageCtrl.dispose();
    _idFocus.dispose();
    _emailFocus.dispose();
    _pwFocus.dispose();
    _pw2Focus.dispose();
    super.dispose();
  }

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
      errorStyle: const TextStyle(color: Colors.red, height: 0.9),
      suffixIcon: suffix,
    );
  }

  String? _validateId(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '아이디를 입력해 주세요.';
    if (s.length < 3) return '아이디는 3자 이상이어야 합니다.';
    return null;
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '이메일을 입력해 주세요.';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(s)) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  String? _validatePw(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '비밀번호를 입력해 주세요.';
    if (s.length < 4) return '비밀번호는 4자 이상이어야 합니다.';
    return null;
  }

  String? _validatePwConfirm(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '비밀번호 확인을 입력해 주세요.';
    if (s != pwCtrl.text.trim()) return '비밀번호가 일치하지 않습니다.';
    return null;
  }

  /// 생년월일: 선택사항, 입력 시에는 YYYY-MM-DD 형식 강제
  String? _validateBirthdate(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null; // 선택사항
    final re = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!re.hasMatch(s)) return '생년월일은 YYYY-MM-DD 형식으로 입력해 주세요.';
    return null;
  }

  Future<void> _submit(AuthState auth) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // 🔹 Gender 코드 변환 (백엔드에서 코드로 쓸 때 대비)
    String? genderCode;
    switch (_gender) {
      case '남성':
        genderCode = 'MALE';
        break;
      case '여성':
        genderCode = 'FEMALE';
        break;
      case '기타':
        genderCode = 'OTHER';
        break;
      default:
        genderCode = null; // '선택 안함'이면 null
    }

    // 🔹 Birthdate (선택) — 이미 validator에서 YYYY-MM-DD 형식 체크
    final bdText = ageCtrl.text.trim();
    final birthdate = bdText.isEmpty ? null : bdText;

    // 🔹 countryCode는 _countryCode 그대로 사용 (예: "KR")
    final countryCode = _countryCode;

    await context.read<AuthState>().signup(
      idCtrl.text.trim(),
      emailCtrl.text.trim(),
      pwCtrl.text.trim(),
      gender: genderCode,
      birthdate: birthdate,
      countries: countryCode == null ? null : [countryCode], // ✅ List<String>로 전달
    );


    if (!mounted) return;

    if (auth.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your email to verify.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final scale = (width / 411).clamp(0.9, 1.1);

    // 화면 바깥 여백(카드 주변)
    final outerHPad = 20 * scale;
    final outerVPad = 20 * scale;

    // 카드 내부 패딩
    final hPad = 20 * scale;
    final vPad = 24 * scale;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 카드 최대 너비 제한(폰에서 과하게 넓어지지 않도록)
          final maxCardWidth =
          (constraints.maxWidth - outerHPad * 2).clamp(320.0, 420.0);

          return Container(
            width: double.infinity,
            color: _pageBg,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: outerHPad,
                  vertical: outerVPad,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxCardWidth,
                    minHeight: constraints.maxHeight - (outerVPad * 2),
                  ),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: vPad,
                      ),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 큰 타이틀: 회원가입
                          Center(
                            child: Text(
                              '회원가입',
                              style: TextStyle(
                                color: _title,
                                fontSize: 48 * scale, // Figma 64는 모바일에 크므로 스케일 다운
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: 32 * scale),

                          // 폼
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 아이디
                                TextFormField(
                                  controller: idCtrl,
                                  focusNode: _idFocus,
                                  textInputAction: TextInputAction.next,
                                  decoration: _rectField('아이디'),
                                  validator: _validateId,
                                  onFieldSubmitted: (_) =>
                                      _emailFocus.requestFocus(),
                                ),
                                SizedBox(height: 12 * scale),

                                // 이메일
                                TextFormField(
                                  controller: emailCtrl,
                                  focusNode: _emailFocus,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _rectField('이메일'),
                                  validator: _validateEmail,
                                  onFieldSubmitted: (_) =>
                                      _pwFocus.requestFocus(),
                                ),
                                SizedBox(height: 12 * scale),

                                // 비밀번호
                                TextFormField(
                                  controller: pwCtrl,
                                  focusNode: _pwFocus,
                                  textInputAction: TextInputAction.next,
                                  obscureText: _obscurePw,
                                  decoration: _rectField(
                                    '비밀번호',
                                    suffix: IconButton(
                                      tooltip: _obscurePw
                                          ? '비밀번호 표시'
                                          : '비밀번호 숨기기',
                                      icon: Icon(
                                        _obscurePw
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      onPressed: () => setState(
                                              () => _obscurePw = !_obscurePw),
                                    ),
                                  ),
                                  validator: _validatePw,
                                  onFieldSubmitted: (_) =>
                                      _pw2Focus.requestFocus(),
                                ),
                                SizedBox(height: 12 * scale),

                                // 비밀번호 확인
                                TextFormField(
                                  controller: pwConfirmCtrl,
                                  focusNode: _pw2Focus,
                                  textInputAction: TextInputAction.done,
                                  obscureText: _obscurePw2,
                                  decoration: _rectField(
                                    '비밀번호 확인',
                                    suffix: IconButton(
                                      tooltip: _obscurePw2
                                          ? '비밀번호 표시'
                                          : '비밀번호 숨기기',
                                      icon: Icon(
                                        _obscurePw2
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      onPressed: () => setState(
                                              () => _obscurePw2 = !_obscurePw2),
                                    ),
                                  ),
                                  validator: _validatePwConfirm,
                                  onFieldSubmitted: (_) =>
                                      FocusScope.of(context).unfocus(),
                                ),
                                SizedBox(height: 12 * scale),

                                // 생년월일 + 성별 (선택사항)
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: ageCtrl,
                                        keyboardType: TextInputType.datetime,
                                        decoration: _rectField(
                                            '생년월일 (선택, YYYY-MM-DD)'),
                                        validator: _validateBirthdate,
                                      ),
                                    ),
                                    SizedBox(width: 12 * scale),
                                    Expanded(
                                      child: InputDecorator(
                                        decoration: _rectField('성별 (선택)')
                                            .copyWith(suffixIcon: null),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            isExpanded: true,
                                            value: _gender,
                                            items: const [
                                              '선택 안함',
                                              '남성',
                                              '여성',
                                              '기타',
                                            ].map((e) {
                                              return DropdownMenuItem(
                                                value: e,
                                                child: Text(
                                                  e,
                                                  style: const TextStyle(
                                                    color: Color(0xFF260101),
                                                    fontSize: 15,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (v) {
                                              if (v != null) {
                                                setState(() => _gender = v);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12 * scale),

                                // ✅ 국적 (선택)
                                DropdownButtonFormField<String>(
                                  value: _countryCode,
                                  decoration: _rectField(
                                    '국가 / 국적 (선택, 나중에 마이페이지에서 변경 가능)',
                                  ),
                                  items: _countryOptions.entries
                                      .map(
                                        (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                  )
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() => _countryCode = v);
                                  },
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 16 * scale),

                          // 에러 메시지
                          Builder(builder: (_) {
                            final auth = context.watch<AuthState>();
                            if (auth.error == null) return const SizedBox();
                            return Padding(
                              padding: EdgeInsets.only(bottom: 8 * scale),
                              child: Text(
                                auth.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }),

                          // 다음(=회원가입) 버튼
                          SizedBox(
                            height: 55 * scale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _border,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: _border, width: 1),
                              ),
                              child: TextButton(
                                onPressed: auth.loading
                                    ? null
                                    : () async => _submit(auth),
                                child: auth.loading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                    : Text(
                                  '다음',
                                  style: TextStyle(
                                    color: _btnFg,
                                    fontSize: 15,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 하단 여백(과도한 여백 방지)
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
