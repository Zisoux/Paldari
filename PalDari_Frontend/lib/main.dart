import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/secure_storage.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/oauth_success_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  if (kIsWeb) {
    usePathUrlStrategy(); // /oauth-success 형태(해시 제거)
  }
  final storage = SecureStorage();
  final api = ApiClient(storage);
  final auth = AuthService(api, storage);
  runApp(MyApp(auth));
}

class MyApp extends StatelessWidget {
  final AuthService auth;
  const MyApp(this.auth, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthState(auth),
      child: MaterialApp(
        title: 'Paldari Auth',
        routes: {
          '/': (_) => const LoginScreen(),
          '/signup': (_) => const SignupScreen(),
          '/home': (_) => const HomeScreen(),
          '/oauth-success': (_) => const OAuthSuccessScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}
