import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final p = auth.profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<AuthState>().logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: p == null
            ? ElevatedButton(
          onPressed: () => context.read<AuthState>().loadProfile(),
          child: const Text('Load Profile'),
        )
            : Text('Hello, ${p['username']} (${p['email']})'),
      ),
    );
  }
}
