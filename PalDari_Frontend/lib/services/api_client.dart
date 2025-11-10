import 'package:dio/dio.dart';
import '../config.dart';
import 'secure_storage.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorage _storage;

  ApiClient(this._storage)
      : _dio = Dio(
    BaseOptions(
      baseUrl: apiBase,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 매 요청마다 최신 토큰을 SecureStorage에서 읽어서 Authorization 헤더 세팅
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) {
          // 디버깅용 로그 (원하면 꺼도 됨)
          // if (kDebugMode) {
          //   print('API error [${e.response?.statusCode}] ${e.requestOptions.uri}');
          // }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
