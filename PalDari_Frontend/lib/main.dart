// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'services/secure_storage.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';

// screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/find_email_screen.dart';
import 'screens/find_pw_screen.dart';
import 'screens/home_screen.dart';
import 'screens/oauth_success_screen.dart';
import 'screens/posts_screen.dart';

void main() {
  if (kIsWeb) {
    usePathUrlStrategy(); // /oauth-success 형태(해시 제거)
  }

  // ✅ 앱 전역에서 공유할 인스턴스들
  final storage = SecureStorage();
  final api = ApiClient(storage);        // Authorization 자동 첨부되는 Dio
  final auth = AuthService(api, storage);

  runApp(
    MultiProvider(
      providers: [
        Provider<SecureStorage>.value(value: storage),
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthState(auth)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paldari',
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');

        if (uri.path == '/oauth-success') {
          final token = uri.queryParameters['token'];
          return MaterialPageRoute(
            builder: (_) => OAuthSuccessScreen(token: token),
            settings: settings,
          );
        }

        switch (uri.path) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/findEmail':
            return MaterialPageRoute(builder: (_) => const FindEmailScreen());
          case '/findPW':
            return MaterialPageRoute(builder: (_) => const FindPwScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const PalHomeScreen());
          case '/posts':
            return MaterialPageRoute(builder: (_) => const PostsScreen());
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
