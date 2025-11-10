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
    // 요청마다 JWT 붙이기
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
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
    throw Exception('Failed to load posts: ${res.statusCode} ${res.statusMessage}');
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

  Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    String? country,
    String? category,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'content': content,
    };

    // PostRequest에 country/category가 있으면 여기 매핑
    if (country != null && country.isNotEmpty) {
      body['country'] = country;
    }
    if (category != null && category.isNotEmpty) {
      body['category'] = category;
    }

    final res = await _dio.post('/api/posts', data: body);

    if (res.statusCode == 201 || res.statusCode == 200) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw Exception('Failed to create post: ${res.statusCode} ${res.statusMessage}');
  }

  Future<void> deletePost(int id) async {
    final res = await _dio.delete('/api/posts/$id');
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('Failed to delete post: ${res.statusCode} ${res.statusMessage}');
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

  Future<void> updateComment(int postId, int commentId,
      {required String content}) async {
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
}
