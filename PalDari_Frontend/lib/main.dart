import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:paldari/screens/edit_profile_screen.dart';
import 'package:paldari/screens/matching_screen.dart';
import 'package:paldari/screens/settings_screen.dart';
//import 'package:paldari/screens/posts_screen.dart'; // ✅

import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/find_email_screen.dart';
import 'screens/find_pw_screen.dart';
import 'screens/home_screen.dart';
import 'screens/oauth_success_screen.dart';
import 'screens/posts_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/my_page_screen.dart';

void main() {
  if (kIsWeb) {
    // /#/oauth-success 대신 /oauth-success 형태로 사용
    usePathUrlStrategy();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // ✅ AuthState는 내부에서 AuthService + ApiClient + SecureStorage 생성
      create: (_) => AuthState(),
      child: MaterialApp(
        title: 'Paldari',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',

        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');

          // ✅ OAuth 성공 콜백 처리
          if (uri.path == '/oauth-success') {
            // access / refresh는 OAuthSuccessScreen 안에서 Uri.base로 직접 읽음
            return MaterialPageRoute(
              builder: (_) => const OAuthSuccessScreen(),
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
            case '/matching':
              return MaterialPageRoute(builder: (_) => const MatchingScreen());
            case '/posts':
              return MaterialPageRoute(builder: (_) => const PostsScreen()); // ✅ const 제거

            case '/chats':
              return MaterialPageRoute(builder: (_) => const ChatListScreen());
            case '/myPage':
              return MaterialPageRoute(builder: (_) => const MyPageScreen());
            case '/editProfile':
              return MaterialPageRoute(builder: (_) => const EditProfileScreen());
            case '/settings':
              return MaterialPageRoute(builder: (_) => const SettingsScreen());
            default:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
        },
      ),
    );
  }
}
