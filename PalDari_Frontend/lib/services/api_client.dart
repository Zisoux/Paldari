import 'package:dio/dio.dart';
import '../config.dart';
import 'secure_storage.dart';

class ApiClient {
  final Dio dio;
  final SecureStorage _storage = SecureStorage();

  ApiClient()
      : dio = Dio(
    BaseOptions(
      baseUrl: apiBase,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        // 요청마다 access 토큰 붙이기
        onRequest: (options, handler) async {
          final accessToken = await _storage.readAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        // 401이면 refresh 시도 후 1회 재시도
        onError: (e, handler) async {
          final status = e.response?.statusCode;
          final alreadyRetried = e.requestOptions.extra['__retry'] == true;

          if (status == 401 && !alreadyRetried) {
            final refreshToken = await _storage.readRefreshToken();
            if (refreshToken == null || refreshToken.isEmpty) {
              return handler.next(e);
            }

            try {
              final refreshRes = await dio.post(
                '/api/auth/refresh',
                data: {'refreshToken': refreshToken},
                options: Options(
                  headers: {
                    'Authorization': null, // 기존 헤더 제거
                  },
                ),
              );

              final data = refreshRes.data;
              final newAccess = data['accessToken'] as String?;
              final newRefresh = data['refreshToken'] as String?;

              if (newAccess != null) {
                await _storage.saveTokens(
                  accessToken: newAccess,
                  refreshToken: newRefresh ?? refreshToken,
                );

                final requestOptions = e.requestOptions;
                requestOptions.headers['Authorization'] = 'Bearer $newAccess';
                requestOptions.extra['__retry'] = true;

                final retryResponse = await dio.fetch(requestOptions);
                return handler.resolve(retryResponse);
              }
            } catch (_) {
              await _storage.deleteTokens();
            }
          }

          return handler.next(e);
        },
      ),
    );
  }
}
