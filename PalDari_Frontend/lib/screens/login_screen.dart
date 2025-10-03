import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final idCtrl = TextEditingController();
  final pwCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Username')),
          TextField(controller: pwCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 12),
          if (auth.error != null) Text(auth.error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: auth.loading ? null : () async {
              final ok = await context.read<AuthState>().login(idCtrl.text, pwCtrl.text);
              if (ok && context.mounted) Navigator.pushReplacementNamed(context, '/home');
            },
            child: auth.loading ? const CircularProgressIndicator() : const Text('Login'),
          ),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/signup'), child: const Text('Go to Sign Up')),
          const Divider(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await launchUrl(Uri.parse(oauthGoogleUrl), mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.login),
            label: const Text('Login with Google'),
          ),
        ]),
      ),
    );
  }
}
