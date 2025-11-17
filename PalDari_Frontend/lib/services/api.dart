// lib/services/api.dart
import 'package:dio/dio.dart';
import '../config.dart';
import 'secure_storage.dart';

class ApiService {
  final Dio _dio;
  final SecureStorage _storage = SecureStorage();

  ApiService()
      : _dio = Dio(
    BaseOptions(
      baseUrl: apiBase,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  ) {
    // 1) 요청마다 access 토큰 붙이기
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _storage.readAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },

        // 2) 401 나오면 refresh 시도 후 한 번 재시도
        onError: (e, handler) async {
          // 이미 한 번 재시도했던 요청이면 바로 종료 (무한 루프 방지)
          final isRetry = e.requestOptions.extra['__retry'] == true;

          if (e.response?.statusCode == 401 && !isRetry) {
            final refreshToken = await _storage.readRefreshToken();
            if (refreshToken == null || refreshToken.isEmpty) {
              return handler.next(e); // 리프레시도 없으면 그냥 실패
            }

            try {
              // refresh 요청
              final refreshRes = await _dio.post(
                '/api/auth/refresh',
                data: {'refreshToken': refreshToken},
                options: Options(
                  headers: {
                    'Authorization': null, // 기존 토큰 헤더 제거
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

                // 원래 요청 복구해서 재시도
                final opts = e.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccess';
                opts.extra['__retry'] = true;

                final cloneResponse = await _dio.fetch(opts);
                return handler.resolve(cloneResponse);
              }
            } catch (_) {
              // refresh 실패시 -> 토큰 삭제하고 그냥 401 흘려보냄
              await _storage.deleteTokens();
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  // ========== POSTS ==========

  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final res = await _dio.get('/api/posts');
    if (res.statusCode == 200) {
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      throw Exception('Unexpected posts response format');
    }
    throw Exception(
        'Failed to load posts: ${res.statusCode} ${res.statusMessage}');
  }

  Future<Map<String, dynamic>> fetchPost(int id) async {
    final res = await _dio.get('/api/posts/$id');
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      error: 'Failed to load post',
      type: DioExceptionType.badResponse,
    );
  }

  /// 언어/내외국인까지 지원하도록 확장된 게시글 생성
  ///
  /// 백엔드 DTO가 아래 키들을 받아야 저장됨:
  /// - country (String)
  /// - category (String)
  /// - language (String)
  /// - isForeigner (bool)  // 불린 규격 선택 시
  /// - persona (String)    // 텍스트 규격 선택 시 ('내국인' | '외국인')
  Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    String? country,
    String? category,
    String? language, // 🔹 추가
    bool? isForeigner, // 🔹 추가
    String? persona, // 🔹 추가
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'content': content,
      if (country != null && country.isNotEmpty) 'country': country,
      if (category != null && category.isNotEmpty) 'category': category,
      if (language != null && language.isNotEmpty) 'language': language,
      if (isForeigner != null) 'isForeigner': isForeigner,
      if (persona != null && persona.isNotEmpty) 'persona': persona,
    };

    final res = await _dio.post('/api/posts', data: body);

    if (res.statusCode == 201 || res.statusCode == 200) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw Exception(
        'Failed to create post: ${res.statusCode} ${res.statusMessage}');
  }

  /// 게시글 수정 (제목/내용/국가/카테고리/언어/내외국인/페르소나)
  Future<Map<String, dynamic>> updatePost({
    required int id,
    required String title,
    required String content,
    String? country,
    String? category,
    String? language,
    bool? isForeigner,
    String? persona,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'content': content,
      if (country != null && country.isNotEmpty) 'country': country,
      if (category != null && category.isNotEmpty) 'category': category,
      if (language != null && language.isNotEmpty) 'language': language,
      if (isForeigner != null) 'isForeigner': isForeigner,
      if (persona != null && persona.isNotEmpty) 'persona': persona,
    };

    final res = await _dio.put('/api/posts/$id', data: body);

    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw Exception(
        'Failed to update post: ${res.statusCode} ${res.statusMessage}');
  }

  Future<void> deletePost(int id) async {
    final res = await _dio.delete('/api/posts/$id');
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(
          'Failed to delete post: ${res.statusCode} ${res.statusMessage}');
    }
  }

  /// 🔥 첨부파일 삭제 (작성자 본인만 가능)
  Future<void> deleteAttachment(int postId, int attachmentId) async {
    final res =
    await _dio.delete('/api/posts/$postId/attachments/$attachmentId');
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(
        'Failed to delete attachment: ${res.statusCode} ${res.statusMessage}',
      );
    }
  }

  // ========== COMMENTS (백엔드 없으면 404 나도 안전하게 처리) ==========

  Future<List<Map<String, dynamic>>> fetchComments(int postId) async {
    try {
      final res = await _dio.get('/api/posts/$postId/comments');
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is List) {
          return data
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      // 댓글 API 아직 없으면(404) 그냥 빈 리스트
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<void> createComment(int postId, {required String content}) async {
    final res = await _dio.post(
      '/api/posts/$postId/comments',
      data: {'content': content},
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to create comment');
    }
  }

  Future<void> updateComment(
      int postId,
      int commentId, {
        required String content,
      }) async {
    final res = await _dio.put(
      '/api/posts/$postId/comments/$commentId',
      data: {'content': content},
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update comment');
    }
  }

  Future<void> deleteComment(int postId, int commentId) async {
    final res = await _dio.delete('/api/posts/$postId/comments/$commentId');
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('Failed to delete comment');
    }
  }

  // ========== TRANSLATION (Papago via backend) ==========

  /// 언어 감지
  /// 백엔드: POST /api/translate/detect
  /// 요청: { "text": "..." }
  /// 응답: { "langCode": "ko" }
  Future<String> detectLanguage(String text) async {
    final res = await _dio.post(
      '/api/translate/detect',
      data: {'text': text},
    );

    if (res.statusCode == 200) {
      final data = res.data;
      if (data is Map && data['langCode'] is String) {
        return data['langCode'] as String;
      }
      throw Exception('Unexpected detectLanguage response format: $data');
    }

    throw Exception(
      'Failed to detect language: ${res.statusCode} ${res.statusMessage}',
    );
  }

  /// 텍스트 번역
  /// 백엔드: POST /api/translate/text
  /// 요청: { "sourceLang": "ko", "targetLang": "en", "text": "안녕" }
  /// 응답: { "translatedText": "Hello" }
  Future<String> translateText({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    final res = await _dio.post(
      '/api/translate/text',
      data: {
        'sourceLang': sourceLang,
        'targetLang': targetLang,
        'text': text,
      },
    );

    if (res.statusCode == 200) {
      final data = res.data;
      if (data is Map && data['translatedText'] is String) {
        return data['translatedText'] as String;
      }
      throw Exception('Unexpected translateText response format: $data');
    }

    throw Exception(
      'Failed to translate text: ${res.statusCode} ${res.statusMessage}',
    );
  }

  /// 자동 번역 헬퍼
  /// - 1) 언어 감지
  /// - 2) targetLang과 같으면 원문 그대로 반환
  /// - 3) 다르면 Papago 번역 호출
  Future<String> autoTranslate({
    required String text,
    required String targetLang,
  }) async {
    // 1) 언어 감지
    final detected = await detectLanguage(text);

    // 동일 언어면 번역 안 하고 원문 리턴
    if (detected == targetLang) return text;

    // 2) 번역
    return translateText(
      text: text,
      sourceLang: detected,
      targetLang: targetLang,
    );
  }
}
