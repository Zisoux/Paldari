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

  /// 홈 화면 Pal 리스트 (현재 유저 기준으로 추천용 Pal 목록)
  /// 백엔드: GET /api/matching/home-pals
  ///
  /// 응답 예시:
  /// [
  ///   { "id": 3, "nickname": "RedIndex", "country": "한국", "tags": ["#생활", "#학업"] },
  ///   ...
  /// ]
  Future<List<Map<String, dynamic>>> fetchHomePals() async {
    final res = await _dio.get('/api/matching/home-pals');

    if (res.statusCode == 200) {
      final data = res.data;
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw Exception('Unexpected home pals response format: $data');
    }

    throw Exception(
      'Failed to load home pals: ${res.statusCode} ${res.statusMessage}',
    );
  }

  // ========== POSTS ==========

  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final res = await _dio.get('/api/posts');
    if (res.statusCode == 200) {
      final data = res.data;
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw Exception('Unexpected posts response format');
    }
    throw Exception(
      'Failed to load posts: ${res.statusCode} ${res.statusMessage}',
    );
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

  /// 게시글 생성 (국가/카테고리/언어/내외국인/페르소나 포함)
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
      'Failed to create post: ${res.statusCode} ${res.statusMessage}',
    );
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
      'Failed to update post: ${res.statusCode} ${res.statusMessage}',
    );
  }

  Future<void> deletePost(int id) async {
    final res = await _dio.delete('/api/posts/$id');
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(
        'Failed to delete post: ${res.statusCode} ${res.statusMessage}',
      );
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
          return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      // 댓글 API 아직 없으면(404) 그냥 빈 리스트
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<void> createComment(
      int postId, {
        required String content,
      }) async {
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

  // ========== MATCHING (조건 매칭 / 랜덤 매칭 / 채팅 생성) ==========

  /// (1) 조건에 맞는 Pal 리스트 전체
  ///
  /// GET /api/matching/candidates
  /// 쿼리 예시:
  ///   ?nationality=일본&category=생활&region=서울&gender=여성&minAge=20&maxAge=30
  Future<List<Map<String, dynamic>>> fetchMatchingCandidates({
    String? nationality, // BUDDY 국적
    String? category, // 카테고리
    String? region, // 상세 지역
    String? gender, // "남성" / "여성" / "무관"
    int? minAge,
    int? maxAge,
  }) async {
    final query = <String, dynamic>{};

    if (nationality != null && nationality.isNotEmpty) {
      query['nationality'] = nationality;
    }
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    if (region != null && region.isNotEmpty) {
      query['region'] = region;
    }
    if (gender != null && gender.isNotEmpty && gender != '무관') {
      query['gender'] = gender;
    }
    if (minAge != null) query['minAge'] = minAge;
    if (maxAge != null) query['maxAge'] = maxAge;

    final res = await _dio.get(
      '/api/matching/candidates',
      queryParameters: query.isEmpty ? null : query,
    );

    if (res.statusCode == 200) {
      final data = res.data;
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw Exception('Unexpected matching response format: ${res.data}');
    }

    if (res.statusCode == 204 || res.statusCode == 404) {
      return [];
    }

    throw Exception(
      'Failed to load candidates: ${res.statusCode} ${res.statusMessage}',
    );
  }

  /// (1-1) 조건에 맞는 Pal 중 "가장 우선순위 높은 1명"만 가져오기
  ///
  /// 지금은 단순히 첫 번째 후보를 선택.
  Future<Map<String, dynamic>?> findBestMatch({
    String? nationality,
    String? category,
    String? region,
    String? gender,
    int? minAge,
    int? maxAge,
  }) async {
    final list = await fetchMatchingCandidates(
      nationality: nationality,
      category: category,
      region: region,
      gender: gender,
      minAge: minAge,
      maxAge: maxAge,
    );

    if (list.isEmpty) return null;
    return list.first;
  }

  /// (2) 조건 없이 랜덤 Pal 1명
  ///
  /// GET /api/matching/random
  /// 응답:
  ///   200: { "id": 3, "username": "...", ... }
  ///   204/404: 매칭 가능 유저 없음
  Future<Map<String, dynamic>?> findRandomMatch() async {
    final res = await _dio.get('/api/matching/random');

    if (res.statusCode == 200) {
      final data = res.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data as Map);
      }
      throw Exception('Unexpected random matching response format: $data');
    }

    if (res.statusCode == 204 || res.statusCode == 404) {
      return null;
    }

    throw Exception(
      'Failed to load random pal: ${res.statusCode} ${res.statusMessage}',
    );
  }

  /// 옛 이름 유지용 래퍼 (혹시 다른 곳에서 쓰고 있으면)
  Future<Map<String, dynamic>?> fetchRandomPal() => findRandomMatch();

  /// (3) 매칭된 유저와의 채팅방 생성 / 기존 방 조회
  ///
  /// POST /api/matching/chat
  /// body: { "targetUserId": 3 }
  ///
  /// 응답:
  ///   { "roomId": 10, "name": "...", "subText": "...", ... }
  Future<Map<String, dynamic>> createChatForMatching({
    required int targetUserId,
  }) async {
    final res = await _dio.post(
      '/api/matching/chat',
      data: {
        'targetUserId': targetUserId,
      },
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = res.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data as Map);
      }
      throw Exception('Unexpected createChatForMatching response: $data');
    }

    throw Exception(
      'Failed to create chat room: ${res.statusCode} ${res.statusMessage}',
    );
  }

  // ========== TRANSLATION (Papago via backend) ==========

  /// 언어 감지
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
  Future<String> autoTranslate({
    required String text,
    required String targetLang,
  }) async {
    final detected = await detectLanguage(text);

    if (detected == targetLang) return text;

    return translateText(
      text: text,
      sourceLang: detected,
      targetLang: targetLang,
    );
  }

  // ========== PROFILE (마이페이지 / 공개 프로필 공통) ==========

  /// 내 프로필 상세 조회 (마이페이지용)
  ///
  /// GET /api/profile/me
  /// 예시 응답:
  /// {
  ///   "nickname": "...",
  ///   "gender": "...",
  ///   "birthdate": "2000-01-01",
  ///   "country": "대한민국",
  ///   "livingIn": "서울",
  ///   "language": "한국어",
  ///   "introduction": "...",
  ///   "tags": ["LIFE", "STUDY"],
  ///   "regions": ["Seoul", "Incheon"]
  /// }
  Future<Map<String, dynamic>> fetchMyProfileDetail() async {
    final res = await _dio.get('/api/profile/me');

    if (res.statusCode == 200) {
      final data = res.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data as Map);
      }
      throw Exception('Unexpected profile detail response format');
    }

    throw Exception(
      'Failed to load profile detail: ${res.statusCode} ${res.statusMessage}',
    );
  }

  /// 다른 유저 공개 프로필 조회 (Pal 프로필 화면용)
  ///
  /// GET /api/profile/{userId}
  Future<Map<String, dynamic>> fetchUserProfileDetail({
    required int userId,
  }) async {
    final res = await _dio.get('/api/profile/$userId');

    if (res.statusCode == 200) {
      final data = res.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data as Map);
      }
      throw Exception('Unexpected user profile detail response format');
    }

    throw Exception(
      'Failed to load user profile: ${res.statusCode} ${res.statusMessage}',
    );
  }

  /// 내 프로필 기본정보 수정
  ///
  /// PATCH /api/profile/update
  /// - null 로 보내지 않는 필드만 수정
  /// - tags / regions:
  ///   - null  : 건드리지 않음
  ///   - []    : 모두 삭제
  Future<void> updateMyProfileBasic({
    String? gender,
    String? birthdate, // "yyyy-MM-dd"
    String? country,
    String? livingIn,
    List<String>? languages,
    String? introduction,
    List<String>? tags,
    List<String>? regions,
  }) async {
    final body = <String, dynamic>{};

    if (gender != null) body['gender'] = gender;
    if (birthdate != null) body['birthdate'] = birthdate;
    if (country != null) body['country'] = country;
    if (livingIn != null) body['livingIn'] = livingIn;
    if (languages != null) body['languages'] = languages;
    if (introduction != null) body['introduction'] = introduction;
    if (tags != null) body['tags'] = tags;
    if (regions != null) body['regions'] = regions;

    final res = await _dio.patch('/api/profile/update', data: body);

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to update profile: ${res.statusCode} ${res.statusMessage}',
      );
    }
  }

  // ========== RATINGS ==========

  /// 채팅방에서 Buddy 평점 남기기
  ///
  /// 백엔드 `POST /api/ratings` 와 연결됨.
  /// - buddyId : 평가 받을 사람의 memberId
  /// - chatRoomId : 어떤 채팅방/매칭에 대한 평가인지
  /// - score : 1 ~ 5
  /// - comment : 선택 사항 (null 또는 빈 문자열이면 전송 안 함)
  Future<void> submitRating({
    required int buddyId,
    required int chatRoomId,
    required int score,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'buddyId': buddyId,
      'chatRoomId': chatRoomId,
      'score': score,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };

    final res = await _dio.post('/api/ratings', data: body);

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        'Failed to submit rating: ${res.statusCode} ${res.statusMessage}',
      );
    }
  }

  /// 마이페이지용: 내가 받은 평점 요약 조회
  ///
  /// GET /api/profile/rating-summary
  /// -> { average, totalCount, count1, ..., count5 }
  Future<Map<String, dynamic>> fetchMyRatingSummary() async {
    final res = await _dio.get('/api/profile/rating-summary');

    if (res.statusCode == 200) {
      final data = res.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data as Map);
      }
      throw Exception('Unexpected rating summary response format');
    }

    throw Exception(
      'Failed to load rating summary: ${res.statusCode} ${res.statusMessage}',
    );
  }
}
