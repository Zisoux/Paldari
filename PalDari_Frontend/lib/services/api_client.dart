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
        // ===== 요청: AccessToken 자동 첨부 =====
        onRequest: (options, handler) async {
          // 이 플래그가 true면 토큰 붙이지 않음 (로그인/리프레시 등)
          final noAuth = options.extra['noAuth'] == true;

          // auth 관련 특정 엔드포인트에는 토큰 안 붙이게 한번 더 방어
          final path = options.path;
          final isAuthEndpoint = path.startsWith('/api/auth/login') ||
              path.startsWith('/api/auth/signup') ||
              path.startsWith('/api/auth/refresh') ||
              path.startsWith('/api/auth/pw-reset');

          if (!noAuth && !isAuthEndpoint) {
            final accessToken = await _storage.readAccessToken();
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
          }

          return handler.next(options);
        },

        // ===== 응답 에러: 401일 때 Refresh 처리 =====
        onError: (e, handler) async {
          final status = e.response?.statusCode;
          final req = e.requestOptions;

          // 이미 재시도한 요청인지
          final alreadyRetried = req.extra['__retry'] == true;

          // 이 요청 자체가 auth/refresh 관련이면 재귀 방지용
          final isAuthCall = req.path.startsWith('/api/auth/login') ||
              req.path.startsWith('/api/auth/signup') ||
              req.path.startsWith('/api/auth/refresh') ||
              req.extra['noAuth'] == true ||
              req.extra['__refreshCall'] == true;

          // 401 + 아직 재시도 안했고 + auth 전용 호출이 아닐 때만 refresh 시도
          if (status == 401 && !alreadyRetried && !isAuthCall) {
            final refreshToken = await _storage.readRefreshToken();
            if (refreshToken == null || refreshToken.isEmpty) {
              // 리프레시 토큰 없으면 그대로 에러
              return handler.next(e);
            }

            try {
              // 🔹 refresh 요청: noAuth + __refreshCall 플래그로 인터셉터 재진입 제어
              final refreshRes = await dio.post(
                '/api/auth/refresh',
                data: {'refreshToken': refreshToken},
                options: Options(
                  extra: {
                    'noAuth': true,
                    '__refreshCall': true,
                  },
                  headers: {
                    // 어떤 토큰도 붙이지 않도록 강제
                    'Authorization': null,
                  },
                ),
              );

              final data = refreshRes.data;
              final newAccess = data['accessToken'] as String?;
              final newRefresh = data['refreshToken'] as String?;

              if (newAccess == null || newAccess.isEmpty) {
                // 이상한 응답이면 토큰 삭제하고 종료
                await _storage.deleteTokens();
                return handler.next(e);
              }

              // 새 토큰 저장
              await _storage.saveTokens(
                accessToken: newAccess,
                refreshToken: newRefresh ?? refreshToken,
              );

              // 원래 요청 재시도 (단 한 번만)
              final RequestOptions newReq = req.copyWith(
                headers: {
                  ...req.headers,
                  'Authorization': 'Bearer $newAccess',
                },
                extra: {
                  ...req.extra,
                  '__retry': true,
                },
              );

              final retryResponse = await dio.fetch(newReq);
              return handler.resolve(retryResponse);
            } catch (_) {
              // refresh 실패 → 토큰 제거하고 원래 에러 전달
              await _storage.deleteTokens();
              return handler.next(e);
            }
          }

          // 조건 안 맞으면 그냥 통과
          return handler.next(e);
        },
      ),
    );
  }
}
