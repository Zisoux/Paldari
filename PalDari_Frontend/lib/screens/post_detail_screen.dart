import 'package:flutter/material.dart';
import '../services/api.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final api = ApiService();
  Map<String, dynamic>? post;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final p = await api.fetchPost(widget.postId);
      setState(() { post = p; });
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('삭제 확인'),
        content: Text('정말 삭제하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.deletePost(widget.postId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제되었습니다.')));
      Navigator.of(context).pop(); // 목록으로 돌아가기
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('상세')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text('에러: $error'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post!['title'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('작성자: ${post!['memberId'] ?? '-'}  ·  ${post!['createdAt'] ?? ''}'),
            Divider(height: 24),
            Expanded(child: SingleChildScrollView(child: Text(post!['content'] ?? ''))),
            Row(
              children: [
                ElevatedButton.icon(onPressed: _delete, icon: Icon(Icons.delete), label: Text('삭제')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
