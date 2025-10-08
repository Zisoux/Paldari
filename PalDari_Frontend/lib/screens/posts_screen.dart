import 'package:flutter/material.dart';
import '../services/api.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final res = await api.fetchPosts();
      setState(() { posts = res; });
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> _onCreatePressed() async {
    // NewPostScreen에서 생성 후 createdId를 반환하도록 구현
    final created = await Navigator.of(context).push<int>(MaterialPageRoute(builder: (_) => NewPostScreen()));
    if (created != null) {
      // 생성된 글이 있으면 상세로 이동
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailScreen(postId: created)));
    } else {
      // 아니면 목록 새로고침
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('게시물 목록')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? Center(child: CircularProgressIndicator())
            : error != null
            ? Center(child: Text('에러: $error'))
            : posts.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(child: Text('게시물이 없습니다.', style: TextStyle(fontSize: 16))),
          ],
        )
            : ListView.separated(
          itemCount: posts.length,
          separatorBuilder: (_, __) => Divider(height: 1),
          itemBuilder: (_, i) {
            final p = posts[i];
            return ListTile(
              title: Text(p['title'] ?? '무제'),
              subtitle: Text('작성자: ${p['memberId'] ?? '-'} · ${p['createdAt'] ?? ''}'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailScreen(postId: (p['id'] as num).toInt())));
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreatePressed,
        child: Icon(Icons.add),
        tooltip: '새 글 작성',
      ),
    );
  }
}
