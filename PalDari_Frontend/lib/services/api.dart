import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 체크용

class ApiService {
  static String _detectBaseUrl() {
    if (kIsWeb) {
      // 웹(Chrome)에서 실행하면 localhost 사용
      return 'http://localhost:8080';
    }
    // 모바일 에뮬레이터(안드로이드)에서는 10.0.2.2 사용, macOS 데스크탑은 localhost
    // 필요하면 환경 변수로 덮어쓸 수 있게 factory에서 baseUrl 인자를 받도록 함
    return 'http://10.0.2.2:8080';
  }

  final Dio dio;
  ApiService({String? baseUrl}) : dio = Dio(BaseOptions(baseUrl: baseUrl ?? _detectBaseUrl(), connectTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 5)));

  // singleton 편한 사용 (원하면 제거)
  static ApiService? _instance;
  factory ApiService.instance({String? baseUrl}) {
    _instance ??= ApiService(baseUrl: baseUrl);
    return _instance!;
  }

  // 게시물 목록
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final resp = await dio.get('/api/posts');
    return List<Map<String, dynamic>>.from(resp.data as List);
  }

  Future<Map<String, dynamic>> fetchPost(int id) async {
    final resp = await dio.get('/api/posts/$id');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> createPost({required int memberId, required String title, required String content}) async {
    final body = {'memberId': memberId, 'title': title, 'content': content};
    final resp = await dio.post('/api/posts', data: body);
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> updatePost(int id, {required int memberId, required String title, required String content}) async {
    final body = {'memberId': memberId, 'title': title, 'content': content};
    final resp = await dio.put('/api/posts/$id', data: body);
    return Map<String, dynamic>.from(resp.data);
  }

  Future<void> deletePost(int id) async {
    await dio.delete('/api/posts/$id');
  }
}
