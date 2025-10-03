import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final idCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final pwCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Username')),
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: pwCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 12),
          if (auth.error != null) Text(auth.error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: auth.loading ? null : () async {
              await context.read<AuthState>().signup(idCtrl.text, emailCtrl.text, pwCtrl.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your email to verify.')));
                Navigator.pop(context);
              }
            },
            child: auth.loading ? const CircularProgressIndicator() : const Text('Sign Up'),
          ),
        ]),
      ),
    );
  }
}
