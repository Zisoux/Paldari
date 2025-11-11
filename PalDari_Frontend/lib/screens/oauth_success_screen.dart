import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OAuthSuccessScreen extends StatefulWidget {
  const OAuthSuccessScreen({super.key});

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
    final uri = Uri.base; // /oauth-success?access=...&refresh=...
    final access = uri.queryParameters['access'];
    final refresh = uri.queryParameters['refresh'];

    if (access != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<AuthState>().setTokensFromCallback(
          accessToken: access,
          refreshToken: refresh,
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    } else {
      // 액세스 토큰이 없으면 실패 처리 (옵션)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
