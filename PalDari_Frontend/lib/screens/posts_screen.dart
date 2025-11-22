import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/pal_bottom_nav.dart';
import 'new_post_screen.dart';
import 'post_detail_screen.dart';
import 'package:characters/characters.dart'; // 👈 유지

class PostsScreen extends StatefulWidget {
  const PostsScreen({Key? key}) : super(key: key);

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final api = ApiService();
  bool loading = true;
  List<Map<String, dynamic>> posts = [];
  String? error;

  // ── UI 팔레트 ───────────────────────────────────────────────────────────
  static const hdr = Color(0xFFFFF7F1);
  static const chipBg = Color(0xFFF2F2F2);
  static const darkTab = Color(0xFF260101);
  static const brand = Color(0xFFFAAD55);
  static const brandText = Color(0xFF734124);

  // ── 필터 상태 ───────────────────────────────────────────────────────────
  final List<String> groups = const ['정보', '소통'];
  String selectedGroup = '정보';

  final List<String> countries = const [
    '말레이시아', '한국', '일본', '미국', '캐나다', '호주', '영국', '독일', '프랑스',
  ];
  String selectedCountry = '일본'; // 시안과 동일

  // 카테고리는 라벨로 관리, 코드 매핑은 헬퍼에서 처리
  final List<String> categories = const ['전체', '생활', '학업', '지역', '안전', '취업'];
  String selectedCategory = '전체';

  // ── ✅ 전역 고정 언어 목록(라벨/코드) + 코드 기반 선택값 ─────────────────
  static const List<Map<String, String>> kLanguages = [
    {'label': '전체', 'code': 'all'},
    {'label': '한국어', 'code': 'ko'},
    {'label': '영어', 'code': 'en'},
    {'label': '일본어', 'code': 'ja'},
    {'label': '말레이어', 'code': 'ms'},
    {'label': '프랑스어', 'code': 'fr'},
    {'label': '독일어', 'code': 'de'},
  ];
  String selectedLanguageCode = 'all'; // 'ko'|'en'|...|'all'

  final List<String> personas = const ['전체', '내국인', '외국인'];
  String selectedPersona = '전체';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await api.fetchPosts(); // 필요시 country/language 파라미터 추가 가능
      setState(() {
        posts = res;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _onCreatePressed() async {
    final created = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => NewPostScreen(
          initialCountry: selectedCountry,
          initialCategory: selectedCategory, // 라벨 그대로 전달 (서버에서 정규화)
          initialLanguage: _langLabelOf(selectedLanguageCode),
          initialPersona: selectedPersona,
          boardGroup: selectedGroup, // ⭐ 지금 선택된 탭(정보/소통) 전달
        ),
      ),
    );

    if (created != null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PostDetailScreen(postId: created)),
      );
      if (result == 'deleted' || result == 'updated') {
        await _load();
      } else {
        await _load();
      }
    } else {
      await _load();
    }
  }

  Future<void> _deletePost(int postId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 게시글을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );

    if (ok == true) {
      try {
        await api.deletePost(postId);
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다.')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
      }
    }
  }

  // 서버에 group 필드가 없으면 기본 '정보'로 처리 + 언어/내외국인 필터 추가
  List<Map<String, dynamic>> get filteredPosts {
    final selectedCategoryCode = _categoryCodeFromAny(selectedCategory);

    return posts.where((p) {
      final postGroup = (p['group'] ?? '정보').toString();
      final postCountry = (p['country'] ?? '').toString();

      // 카테고리: 서버는 코드(ALL/LIFE/...)를 줄 수 있고, 과거 데이터는 한글일 수 있음 → 모두 코드로 정규화
      final rawCategory = (p['category'] ?? '').toString();
      final postCategoryCode = _categoryCodeFromAny(rawCategory);

      // 언어: 다양한 키/형식 수용 → 코드로 정규화
      final rawLang =
      (p['language'] ?? p['lang'] ?? p['postLang'] ?? '').toString();
      final postLangCode =
      _normalizeLangCode(rawLang); // '' → '' / '한국어' → 'ko' / 'en' → 'en'

      // 내/외국인: 불린/문자 모두 수용
      final bool? foreignBool = (() {
        final v = p['isForeigner'] ?? p['foreigner'] ?? p['isForeign'];
        if (v is bool) return v;
        if (v is num) return v != 0;
        if (v is String) {
          final s = v.toLowerCase();
          if (['true', '1', 'yes', 'y'].contains(s)) return true;
          if (['false', '0', 'no', 'n'].contains(s)) return false;
        }
        return null;
      })();

      // 텍스트 기반 후보: persona, userType, nationalityType, memberType 등
      final String personaText = (() {
        final raw = (p['persona'] ??
            p['userType'] ??
            p['nationalityType'] ??
            p['memberType'] ??
            '')
            .toString()
            .toUpperCase();
        if (raw.contains('NATIVE') || raw.contains('KOREAN') || raw == 'KR') {
          return '내국인';
        }
        if (raw.contains('FOREIGN') || raw.contains('FOREIGNER')) {
          return '외국인';
        }
        return '';
      })();

      final groupMatch = postGroup == selectedGroup;
      final countryMatch =
      selectedCountry.isEmpty ? true : postCountry.contains(selectedCountry);

      // ✅ 카테고리 매칭: 코드 기준 ('ALL' 이면 전체)
      final categoryMatch = (selectedCategoryCode == 'ALL')
          ? true
          : (postCategoryCode == selectedCategoryCode);

      // ✅ 언어 매칭(전역 코드 기준). 'all'이면 조건 미적용
      final languageMatch = (selectedLanguageCode == 'all')
          ? true
          : (postLangCode == selectedLanguageCode);

      // 내/외국인 매칭
      final personaMatch = (selectedPersona == '전체')
          ? true
          : (() {
        if (foreignBool != null) {
          return selectedPersona == '외국인'
              ? foreignBool == true
              : foreignBool == false;
        }
        if (personaText.isNotEmpty) {
          return selectedPersona == personaText;
        }
        // 정보가 전혀 없으면 통과
        return true;
      })();

      return groupMatch &&
          countryMatch &&
          categoryMatch &&
          languageMatch &&
          personaMatch;
    }).toList();
  }

  // ── helpers: 언어 정규화/라벨 매핑 ────────────────────────────────────────
  static String _normalizeLangCode(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return ''; // 미지정은 빈 문자열 취급

    // 코드 그대로 들어온 경우
    const codes = {'all', 'ko', 'en', 'ja', 'ms', 'fr', 'de'};
    if (codes.contains(v)) return v;

    // 라벨/별칭 매핑
    switch (v) {
      case '전체':
        return 'all';
      case '한국어':
      case 'korean':
      case 'kr':
      case 'ko-kr':
        return 'ko';

      case '영어':
      case 'english':
      case 'us':
      case 'en-us':
      case 'en-uk':
        return 'en';

      case '일본어':
      case 'japanese':
      case 'jp':
      case 'ja-jp':
        return 'ja';

      case '말레이어':
      case 'malay':
      case 'ms-my':
        return 'ms';

      case '프랑스어':
      case 'french':
      case 'fr-fr':
        return 'fr';

      case '독일어':
      case 'german':
      case 'de-de':
        return 'de';
    }
    // 모르는 값 → 그대로 코드처럼 쓰되, 영문/숫자 아니면 기타
    final alnum = RegExp(r'^[a-z0-9_-]+$');
    return alnum.hasMatch(v) ? v : '';
  }

  static String _langLabelOf(String code) {
    final m = kLanguages.firstWhere(
          (e) => e['code'] == code,
      orElse: () => const {'label': '전체', 'code': 'all'},
    );
    return m['label']!;
  }

  // ── helpers: 카테고리 코드/라벨 매핑 ─────────────────────────────────────
  /// 라벨 또는 코드(any)를 받아 항상 코드(ALL/LIFE/...)로 변환
  String _categoryCodeFromAny(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';

    // 이미 코드인 경우
    switch (s.toUpperCase()) {
      case 'ALL':
      case 'LIFE':
      case 'STUDY':
      case 'REGION':
      case 'SAFETY':
      case 'JOB':
        return s.toUpperCase();
    }

    // 라벨 → 코드
    switch (s) {
      case '전체':
        return 'ALL';
      case '생활':
        return 'LIFE';
      case '학업':
        return 'STUDY';
      case '지역':
        return 'REGION';
      case '안전':
        return 'SAFETY';
      case '취업':
        return 'JOB';
    }

    return s; // 모르는 값은 그대로
  }

  /// 코드(ALL/LIFE/...)를 한글 라벨로 변환 (UI 표시용)
  String _categoryLabelFromCode(String code) {
    switch (code.toUpperCase()) {
      case 'ALL':
        return '전체';
      case 'LIFE':
        return '생활';
      case 'STUDY':
        return '학업';
      case 'REGION':
        return '지역';
      case 'SAFETY':
        return '안전';
      case 'JOB':
        return '취업';
      default:
        return code; // 혹시 모르는 값이면 그대로
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hdr,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: hdr,
        centerTitle: true,
        title: const Text(
          '커뮤니티',
          style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            tooltip: '검색',
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {}, // TODO: 검색 화면 연결
          ),
          IconButton(
            tooltip: '알림',
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {}, // TODO: 알림 화면 연결
          ),
          IconButton(
            tooltip: '필터',
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () {}, // TODO: 고급 필터 시트
          ),
        ],
      ),
      bottomNavigationBar: const PalBottomNav(currentIndex: 3),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            // ── 상단: 그룹 세그먼트 + 국가/언어/내외국인 컨트롤 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  // 그룹 세그먼트
                  Expanded(
                    child: _GroupSegment(
                      value: selectedGroup,
                      onChanged: (v) => setState(() => selectedGroup = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 국가 드롭다운
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: selectedCountry,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(Icons.expand_more,
                            size: 20, color: Colors.black87),
                        items: countries
                            .map(
                              (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedCountry = v!),
                      ),
                    ),
                  ),
                  // 언어 드롭다운
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: selectedLanguageCode,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(Icons.expand_more,
                            size: 20, color: Colors.black87),
                        items: kLanguages
                            .map(
                              (e) => DropdownMenuItem<String>(
                            value: e['code'],
                            child: Text(
                              e['label']!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (code) =>
                            setState(() => selectedLanguageCode = code!),
                      ),
                    ),
                  ),
                  // 내/외국인 세그먼트
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: personas.map((g) {
                        final selected = g == selectedPersona;
                        return InkWell(
                          onTap: () => setState(() => selectedPersona = g),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                              selected ? darkTab : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              g,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF595959),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── 카테고리 탭 (전체/생활/학업/지역/안전/취업) ──
            SizedBox(
              height: 45,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = categories[i];
                  final isSelected = c == selectedCategory;
                  return ChoiceChip(
                    label: Text(c),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => selectedCategory = c),
                    selectedColor: brand,
                    backgroundColor: chipBg,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF9F9FA1),
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                  );
                },
              ),
            ),

            const Divider(height: 1, color: Color(0xFFEDEDED)),

            // ── 게시글 리스트 ──
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(child: Text('에러: $error'))
                  : filteredPosts.isEmpty
                  ? ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                      child: Text('게시물이 없습니다.',
                          style: TextStyle(fontSize: 16))),
                ],
              )
                  : ListView.builder(
                padding:
                const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                itemCount: filteredPosts.length,
                itemBuilder: (_, i) {
                  final p = filteredPosts[i];
                  final id =
                  (p['id'] as num).toInt();
                  final title =
                  (p['title'] ?? '무제').toString();
                  final content =
                  (p['content'] ?? '').toString();
                  final author =
                  (p['authorUsername'] ?? '-')
                      .toString();
                  final level =
                  (p['level'] ?? 'Lv.3').toString();
                  final country =
                  (p['country'] ?? '국가 미지정')
                      .toString();
                  final createdAt =
                  (p['createdAt'] ?? '')
                      .toString();

                  final rawCategory =
                  (p['category'] ?? '전체')
                      .toString();
                  final postCategoryCode =
                  _categoryCodeFromAny(
                      rawCategory);
                  final categoryLabel =
                  _categoryLabelFromCode(
                      postCategoryCode);

                  final likeCount =
                  (p['likeCount'] ??
                      p['likes'] ??
                      0)
                      .toString();
                  final commentCount =
                  (p['commentCount'] ??
                      p['comments'] ??
                      0)
                      .toString();

                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator
                          .of(context)
                          .push(
                        MaterialPageRoute(
                            builder: (_) =>
                                PostDetailScreen(
                                    postId: id)),
                      );
                      if (result == 'deleted' ||
                          result == 'updated') {
                        await _load();
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets
                          .symmetric(vertical: 6),
                      elevation: 0.5,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                              12)),
                      child: Padding(
                        padding:
                        const EdgeInsets.fromLTRB(
                            12, 12, 8, 10),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                  const Color(
                                      0xFFF39D52),
                                  child: Text(
                                    _initials(
                                        author),
                                    style:
                                    const TextStyle(
                                      color: _PostsScreenState
                                          .brandText,
                                      fontWeight:
                                      FontWeight
                                          .w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                              author,
                                              style: const TextStyle(
                                                  fontSize:
                                                  14,
                                                  fontWeight:
                                                  FontWeight.w600)),
                                          const SizedBox(
                                              width:
                                              6),
                                          Text(
                                              level,
                                              style: const TextStyle(
                                                  fontSize:
                                                  12,
                                                  color:
                                                  Colors.grey)),
                                          const SizedBox(
                                              width:
                                              4),
                                          const Icon(
                                              Icons
                                                  .verified_rounded,
                                              size:
                                              16,
                                              color: Colors
                                                  .green),
                                        ],
                                      ),
                                      const SizedBox(
                                          height: 2),
                                      Text(
                                        '$country · $createdAt',
                                        style: const TextStyle(
                                            fontSize:
                                            12,
                                            color: Colors
                                                .grey),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons
                                          .bookmark_border,
                                      color: Colors
                                          .black54),
                                  onPressed:
                                      () {}, // TODO: 북마크
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.more_horiz,
                                      color: Colors
                                          .black54),
                                  onPressed:
                                      () {}, // TODO: 더보기 메뉴
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight
                                      .w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              content,
                              maxLines: 2,
                              overflow:
                              TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Colors
                                      .black87,
                                  height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: -6,
                              children: [
                                _tag('#$categoryLabel'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                    Icons
                                        .thumb_up_alt_outlined,
                                    size: 14,
                                    color:
                                    Colors.grey),
                                const SizedBox(width: 4),
                                Text(likeCount,
                                    style:
                                    const TextStyle(
                                        color: Colors
                                            .grey)),
                                const SizedBox(
                                    width: 12),
                                const Icon(
                                    Icons
                                        .chat_bubble_outline,
                                    size: 14,
                                    color:
                                    Colors.grey),
                                const SizedBox(width: 4),
                                Text(commentCount,
                                    style:
                                    const TextStyle(
                                        color: Colors
                                            .grey)),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                      Icons
                                          .delete_outline,
                                      size: 18,
                                      color: Colors
                                          .redAccent),
                                  onPressed: () =>
                                      _deletePost(
                                          id),
                                  tooltip: '삭제',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreatePressed,
        backgroundColor: brand,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: '새 글 작성',
      ),
    );
  }

  String _initials(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first;
    return (parts.first.characters.first +
        parts.last.characters.first);
  }

  Widget _tag(String text) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF595959),
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 정보/소통 세그먼트
class _GroupSegment extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _GroupSegment({required this.value, required this.onChanged});

  static const chipBg = Color(0xFFF2F2F2);
  static const darkTab = Color(0xFF260101);

  @override
  Widget build(BuildContext context) {
    final groups = const ['정보', '소통'];
    return Container(
      decoration:
      BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: groups.map((g) {
          final selected = g == value;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(g),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                  selected ? darkTab : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  g,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(0xFF595959),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
