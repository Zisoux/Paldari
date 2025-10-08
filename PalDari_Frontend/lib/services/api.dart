// lib/services/api.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static ApiService? _instance;

  factory ApiService({String? baseUrl}) {
    _instance ??= ApiService._internal(baseUrl: baseUrl);
    return _instance!;
  }

  ApiService._internal({String? baseUrl})
      : dio = Dio(BaseOptions(
    baseUrl: baseUrl ?? _detectBaseUrl(),
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
    headers: {'Content-Type': 'application/json'},
  ));

  final Dio dio;

  static String _detectBaseUrl() {
    // 웹은 localhost, 모바일 에뮬레이터는 10.0.2.2 사용
    if (kIsWeb) return 'http://127.0.0.1:8080';
    // macOS 데스크탑에서 실행하면 localhost
    // Android emulator: 10.0.2.2
    // iOS simulator: localhost
    return 'http://10.0.2.2:8080';
  }

  // --- Posts ---
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final resp = await dio.get('/api/posts');
    return List<Map<String, dynamic>>.from(resp.data as List);
  }

  Future<Map<String, dynamic>> fetchPost(int id) async {
    final resp = await dio.get('/api/posts/$id');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> createPost({
    required int memberId,
    required String title,
    required String content,
  }) async {
    final resp = await dio.post('/api/posts', data: {
      'memberId': memberId,
      'title': title,
      'content': content,
    });
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> updatePost(
      int id, {required int memberId, required String title, required String content}) async {
    final resp = await dio.put('/api/posts/$id', data: {
      'memberId': memberId,
      'title': title,
      'content': content,
    });
    return Map<String, dynamic>.from(resp.data);
  }

  Future<void> deletePost(int id) async {
    await dio.delete('/api/posts/$id');
  }

  // --- Comments ---
  Future<List<Map<String, dynamic>>> fetchComments(int postId) async {
    final resp = await dio.get('/api/posts/$postId/comments');
    return List<Map<String, dynamic>>.from(resp.data as List);
  }

  Future<Map<String, dynamic>> createComment(int postId, {required String content}) async {
    final resp = await dio.post('/api/posts/$postId/comments', data: {'content': content});
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> updateComment(int postId, int commentId, {required String content}) async {
    final resp = await dio.put('/api/posts/$postId/comments/$commentId', data: {'content': content});
    return Map<String, dynamic>.from(resp.data);
  }

  Future<void> deleteComment(int postId, int commentId) async {
    await dio.delete('/api/posts/$postId/comments/$commentId');
  }
}
