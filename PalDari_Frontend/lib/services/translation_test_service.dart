import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TranslationTestService {
  TranslationTestService({
    required this.baseUrl,
  });

  final String baseUrl;

  // Android Emulator에서 PC의 Spring Boot 서버로 접속하는 주소
  // Chrome Web 테스트 시에는 http://localhost:8080 으로 변경
  static const String testBaseUrl = 'http://10.0.2.2:8080';

  Future<void> resetTranslationTest() async {
    final uri = Uri.parse('$testBaseUrl/api/translate/test/reset');

    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.post(uri);
      stopwatch.stop();

      debugPrint('================ PalDari Mock Translation Test Reset ================');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('App Response Time: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('Response Body: ${response.body}');
      debugPrint('=====================================================================');
    } catch (e) {
      stopwatch.stop();

      debugPrint('================ PalDari Mock Translation Test Reset Error ================');
      debugPrint('App Response Time: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('Error: $e');
      debugPrint('==========================================================================');
    }
  }

  Future<void> resetPapagoTest() async {
    final uri = Uri.parse('$testBaseUrl/api/translate/test/papago-reset');

    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.post(uri);
      stopwatch.stop();

      debugPrint('================ PalDari Papago Test Reset ================');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('App Response Time: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('Response Body: ${response.body}');
      debugPrint('============================================================');
    } catch (e) {
      stopwatch.stop();

      debugPrint('================ PalDari Papago Test Reset Error ================');
      debugPrint('App Response Time: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('Error: $e');
      debugPrint('=================================================================');
    }
  }

  Future<void> testMockTranslationApi({
    required bool useRedis,
    String sourceLang = 'ko',
    String targetLang = 'en',
    String text = '안녕하세요',
  }) async {
    final mode = useRedis ? 'redis-cache' : 'no-cache';

    final uri = Uri.parse('$testBaseUrl/api/translate/test/$mode').replace(
      queryParameters: {
        'sourceLang': sourceLang,
        'targetLang': targetLang,
        'text': text,
      },
    );

    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(uri);
      stopwatch.stop();

      debugPrint('================ PalDari Mock Translation Test ================');
      debugPrint('Mode: $mode');
      debugPrint('Request: $sourceLang -> $targetLang / "$text"');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('App Response Time: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('Response Body: ${response.body}');
      debugPrint('===============================================================');
    } catch (e) {
      stopwatch.stop();

      debugPrint('================ PalDari Mock Translation Test Error ================');
      debugPrint('Mode: $mode');
      debugPrint('Request: $sourceLang -> $targetLang / "$text"');
      debugPrint('App Response Time: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('Error: $e');
      debugPrint('====================================================================');
    }
  }

  Future<void> testPapagoTranslationApi({
    required bool useRedis,
    String sourceLang = 'ko',
    String targetLang = 'en',
    String text = '안녕하세요',
  }) async {
    final mode = useRedis ? 'papago-redis-cache' : 'papago-no-cache';

    final uri = Uri.parse('$testBaseUrl/api/translate/test/$mode').replace(
      queryParameters: {
        'sourceLang': sourceLang,
        'targetLang': targetLang,
        'text': text,
      },
    );

    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(uri);
      stopwatch.stop();

      debugPrint('================ PalDari Papago Translation Test ================');
      debugPrint('Mode: $mode');
      debugPrint('Request: $sourceLang -> $targetLang / "$text"');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('App Response Time: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('Response Body: ${response.body}');
      debugPrint('================================================================');
    } catch (e) {
      stopwatch.stop();

      debugPrint('================ PalDari Papago Translation Test Error ================');
      debugPrint('Mode: $mode');
      debugPrint('Request: $sourceLang -> $targetLang / "$text"');
      debugPrint('App Response Time: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('Error: $e');
      debugPrint('=====================================================================');
    }
  }

  Future<void> runMockBasicTest() async {
    debugPrint('================ PalDari Mock Basic Translation Test Start ================');

    await resetTranslationTest();
    await testMockTranslationApi(useRedis: false);
    await testMockTranslationApi(useRedis: false);

    await resetTranslationTest();
    await testMockTranslationApi(useRedis: true);
    await testMockTranslationApi(useRedis: true);
    await testMockTranslationApi(useRedis: true);

    debugPrint('================ PalDari Mock Basic Translation Test End ================');
  }

  Future<void> runPapagoBasicTest() async {
    debugPrint('================ PalDari Papago Basic Translation Test Start ================');

    // 1. 실제 Papago No Cache 테스트
    await resetPapagoTest();
    await testPapagoTranslationApi(useRedis: false);
    await testPapagoTranslationApi(useRedis: false);

    // 2. 실제 Papago Redis Cache 테스트
    await resetPapagoTest();
    await testPapagoTranslationApi(useRedis: true);  // 첫 요청: Cache Miss 예상
    await testPapagoTranslationApi(useRedis: true);  // 두 번째 요청: Cache Hit 예상
    await testPapagoTranslationApi(useRedis: true);  // 세 번째 요청: Cache Hit 예상

    debugPrint('================ PalDari Papago Basic Translation Test End ================');
  }
}