import 'package:flutter/foundation.dart';

/// Web(Chrome) / Android Emulator 환경 분기용
/// - Web: localhost:8080 (PC에서 같이 띄운 백엔드)
/// - Mobile/Emulator: 10.0.2.2:8080 (에뮬레이터 -> 호스트 PC)
const String _webBase = 'http://localhost:8080';
const String _mobileBase = 'http://10.0.2.2:8080';

String get apiBase => kIsWeb ? _webBase : _mobileBase;

/// STOMP SockJS 엔드포인트 (Spring: /ws-chat + withSockJS)
String get wsEndpoint => '$apiBase/ws-chat';

/// Google OAuth 시작 URL
String get oauthGoogleUrl => '$apiBase/oauth2/authorization/google';
