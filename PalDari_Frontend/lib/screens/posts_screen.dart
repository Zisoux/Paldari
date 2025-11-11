import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/pal_bottom_nav.dart';
import 'new_post_screen.dart';
import 'post_detail_screen.dart';

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

  // 🔹 국가 탭 & 카테고리 탭
  final List<String> countries = ['한국', '일본', '말레이시아'];
  final List<String> categories = ['전체', '생활', '학업', '지역', '안전', '취업'];
  String selectedCountry = '한국';
  String selectedCategory = '전체';

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
      final res = await api.fetchPosts();
      setState(() {
        posts = res;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _onCreatePressed() async {
    final created = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => NewPostScreen(
          initialCountry: selectedCountry,
          initialCategory: selectedCategory,
        ),
      ),
    );

    if (created != null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(postId: created),
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await api.deletePost(postId);
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 삭제되었습니다.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  // 🔹 국가 + 카테고리 필터
  List<Map<String, dynamic>> get filteredPosts {
    return posts.where((p) {
      final countryMatch = (p['country'] ?? '').contains(selectedCountry);
      final categoryMatch = selectedCategory == '전체'
          ? true
          : (p['category'] ?? '').contains(selectedCategory);
      return countryMatch && categoryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F1),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: const Color(0xFFFFF7F1),
        centerTitle: true,
        title: const Text(
          '커뮤니티',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: const PalBottomNav(
        currentIndex: 3, // ✅ 커뮤니티 탭 인덱스
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            // 🔸 1. 국가 선택 탭
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: countries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = countries[i];
                  final isSelected = c == selectedCountry;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedCountry = c);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF260101)
                            : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF595959),
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 🔸 2. 카테고리 탭
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  final isSelected = c == selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedCategory = c);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFAAD55)
                            : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF595959),
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF2F2F2)),

            // 🔸 게시글 목록
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
                    child: Text(
                      '게시물이 없습니다.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                itemCount: filteredPosts.length,
                itemBuilder: (_, i) {
                  final p = filteredPosts[i];
                  return GestureDetector(
                    onTap: () async {
                      final result =
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(
                            postId: (p['id'] as num).toInt(),
                          ),
                        ),
                      );
                      if (result == 'deleted' ||
                          result == 'updated') {
                        await _load();
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                              children: [
                                Text(
                                  p['title'] ?? '무제',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color:
                                    Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      _deletePost(
                                        (p['id'] as num)
                                            .toInt(),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p['content'] ?? '',
                              maxLines: 2,
                              overflow:
                              TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${p['country'] ?? '국가 미지정'} · ${p['category'] ?? '카테고리 없음'}\n작성자: ${p['authorUsername'] ?? '-'} · ${p['createdAt'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
        backgroundColor: const Color(0xFFFAAD55),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: '새 글 작성',
      ),
    );
  }
}
