import 'package:dio/dio.dart';
import '../config.dart';
import 'secure_storage.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(baseUrl: apiBase));
  final SecureStorage _storage;

  ApiClient(this._storage) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;
}
