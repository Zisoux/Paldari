import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class FindEmailScreen extends StatefulWidget {
  const FindEmailScreen({super.key});

  @override
  State<FindEmailScreen> createState() => _FindEmailScreenState();
}

class _FindEmailScreenState extends State<FindEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  final Color _pageBg = const Color(0xFFFFF7F1);
  final Color _cardBg = const Color(0xFFFFF7F1);
  final Color _border = const Color(0xFFF29D52);
  final Color _title = const Color(0xFF260101);

  bool _checking = false;
  String? _resultText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  InputDecoration _rectField(String label) {
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
    );
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '이메일 주소를 입력해 주세요.';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(s)) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  Future<void> _checkEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _checking = true;
      _resultText = null;
    });

    //final auth = context.read<AuthState>();
    final res = await context.read<AuthState>()
        .checkEmailAndFetchUsername(_emailCtrl.text);

    setState(() {
      _checking = false;
      _resultText = res.message; // 그대로 보여주기
    });

// 존재/아이디 값이 필요하면:
    if (res.exists) {
      // res.username 에 있으면 사용
    }

  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final scale = (width / 411).clamp(0.9, 1.1);
    final outerHPad = 20 * scale;
    final outerVPad = 20 * scale;
    final hPad = 20 * scale;
    final vPad = 24 * scale;

    return Scaffold(
      appBar: AppBar(title: const Text('아이디 찾기 (이메일로 확인)')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxCardWidth =
          ((constraints.maxWidth - outerHPad * 2).clamp(320.0, 420.0)).toDouble();

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
                      padding:
                      EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '아이디 / 비밀번호 찾기',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 32 * scale,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 28 * scale),

                            Text(
                              '이메일로 아이디 확인',
                              style: TextStyle(
                                color: _title,
                                fontSize: 15 * scale,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12 * scale),

                            TextFormField(
                              controller: _emailCtrl,
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _rectField('이메일 주소'),
                              validator: _validateEmail,
                              onFieldSubmitted: (_) => _checkEmail(),
                            ),
                            SizedBox(height: 16 * scale),

                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 55 * scale,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text(
                                          '이전',
                                          style: TextStyle(
                                            color: Color(0xFF141414),
                                            fontSize: 15,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12 * scale),
                                Expanded(
                                  child: SizedBox(
                                    height: 55 * scale,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: _border,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(color: _border, width: 1),
                                      ),
                                      child: TextButton(
                                        onPressed: _checking ? null : _checkEmail,
                                        child: _checking
                                            ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                            AlwaysStoppedAnimation(
                                                Colors.white),
                                          ),
                                        )
                                            : const Text(
                                          '확인',
                                          style: TextStyle(
                                            color: Color(0xFFFFF7F1),
                                            fontSize: 15,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (_resultText != null) ...[
                              SizedBox(height: 16 * scale),
                              Text(
                                _resultText!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
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
