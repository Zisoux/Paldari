import 'package:dio/dio.dart';
import '../config.dart';
import 'secure_storage.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: apiBase, // 예: http://127.0.0.1:8080  / Android 에뮬: http://10.0.2.2:8080
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  final SecureStorage _storage;

  ApiClient(this._storage) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          // 🔎 디버그 확인 (필요 시 주석 해제)
          // print('AUTH HEADER => ${options.headers['Authorization']}');
        } else {
          // print('AUTH HEADER => (없음)');
        }
        return handler.next(options);
      },
    ));

    // (선택) 응답/에러 로깅
    // _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  Dio get dio => _dio;
}
