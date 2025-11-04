import 'package:flutter/material.dart';
import 'package:paldari/screens/find_email_screen.dart';
import 'package:paldari/screens/find_pw_screen.dart';
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
        initialRoute: '/',

        // query parameter 포함 라우트 처리
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');

          if (uri.path == '/oauth-success') {
            final token = uri.queryParameters['token'];
            return MaterialPageRoute(
              builder: (context) => OAuthSuccessScreen(token: token),
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
            default:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
        },

        // 기존 routes 제거 (onGenerateRoute로 통합)
      ),
    );
  }
}
