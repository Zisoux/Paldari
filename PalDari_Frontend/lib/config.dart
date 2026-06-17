import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Web / Android Emulator / iOS Simulator 환경 분기용
/// - Web: localhost:8080
/// - Android Emulator: 10.0.2.2:8080
/// - iOS Simulator: localhost:8080
const String _webBase = 'http://localhost:8080';
const String _androidEmulatorBase = 'http://10.0.2.2:8080';
const String _iosSimulatorBase = 'http://localhost:8080';

String get apiBase {
  if (kIsWeb) return _webBase;

  if (Platform.isAndroid) {
    return _androidEmulatorBase;
  }

  if (Platform.isIOS) {
    return _iosSimulatorBase;
  }

  return _webBase;
}

/// STOMP SockJS 엔드포인트
String get wsEndpoint => '$apiBase/ws-chat';

/// Google OAuth 시작 URL
String get oauthGoogleUrl => '$apiBase/oauth2/authorization/google';