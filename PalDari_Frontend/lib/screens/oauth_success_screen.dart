import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OAuthSuccessScreen extends StatefulWidget {
  const OAuthSuccessScreen({super.key});
  @override State<OAuthSuccessScreen> createState() => _OAuthSuccessScreenState();
}

class _OAuthSuccessScreenState extends State<OAuthSuccessScreen> {
  @override
  void initState() {
    super.initState();
    final uri = Uri.base; // /oauth-success?token=...
    final token = uri.queryParameters['token'];
    if (token != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<AuthState>().setTokenFromCallback(token);
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
