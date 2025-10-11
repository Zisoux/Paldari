import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OAuthSuccessScreen extends StatefulWidget {
  final String? token; // query parameter token을 받기 위해 추가

  const OAuthSuccessScreen({super.key, this.token});

  @override
  State<OAuthSuccessScreen> createState() => _OAuthSuccessScreenState();
}

class _OAuthSuccessScreenState extends State<OAuthSuccessScreen> {
  @override
  void initState() {
    super.initState();
    _handleOAuthRedirect();
  }

  void _handleOAuthRedirect() {
    // Flutter 웹에서 redirect URL에서 token 읽기
    final uri = Uri.base; // /oauth-success?token=...
    final token = widget.token ?? uri.queryParameters['token'];

    if (token != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // AuthState에 token 저장
        await context.read<AuthState>().setTokenFromCallback(token);
        if (mounted) {
          // 저장 후 홈 화면으로 이동
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
