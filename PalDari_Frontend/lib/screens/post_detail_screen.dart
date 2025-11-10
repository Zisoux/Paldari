// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';                 // 에러 코드 확인용
import 'package:provider/provider.dart';
import '../services/api_client.dart';         // ✅ ApiClient 사용(Authorization 자동 첨부)

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Map<String, dynamic>? post;
  List<Map<String, dynamic>> comments = [];
  bool loadingPost = true;
  bool loadingComments = true;
  String? postError;
  String? commentsError;

  // comment form controls
  final TextEditingController _commentController = TextEditingController();
  bool submittingComment = false;

  // edit state
  int? editingCommentId;
  final TextEditingController _editingController = TextEditingController();
  bool submittingEdit = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editingController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadPost(), _loadComments()]);
  }

  Future<void> _loadPost() async {
    setState(() {
      loadingPost = true;
      postError = null;
    });
    try {
      final api = context.read<ApiClient>();                   // ✅ 공용 dio
      final res = await api.dio.get('/api/posts/${widget.postId}');
      if (!mounted) return;
      setState(() {
        post = Map<String, dynamic>.from(res.data as Map);
      });
    } on DioException catch (e) {
      // ✅ 404면 이미 삭제됨: 안내 후 목록으로 복귀 + 'deleted' 반환
      if (e.response?.statusCode == 404) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 삭제된 게시글입니다.')),
        );
        Navigator.of(context).pop('deleted');
        return;
      }
      if (!mounted) return;
      setState(() => postError = e.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => postError = e.toString());
    } finally {
      if (mounted) setState(() => loadingPost = false);
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      loadingComments = true;
      commentsError = null;
    });
    try {
      final api = context.read<ApiClient>();                   // ✅ 공용 dio
      final res = await api.dio.get('/api/posts/${widget.postId}/comments');
      if (!mounted) return;
      setState(() {
        comments = List<Map<String, dynamic>>.from(res.data as List);
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => commentsError = e.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => commentsError = e.toString());
    } finally {
      if (mounted) setState(() => loadingComments = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('댓글을 입력하세요')));
      return;
    }
    setState(() => submittingComment = true);
    try {
      final api = context.read<ApiClient>();                   // ✅ 토큰 자동 첨부
      await api.dio.post('/api/posts/${widget.postId}/comments', data: {
        'content': text,
      });
      _commentController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('댓글 작성 완료')));
      await _loadComments();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.statusCode == 401
          ? '댓글 작성 실패: 로그인 후 다시 시도해 주세요 (401)'
          : '댓글 작성 실패 (${e.response?.statusCode ?? e.type}): ${e.response?.data ?? e.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => submittingComment = false);
    }
  }

  void _startEdit(Map<String, dynamic> comment) {
    setState(() {
      editingCommentId = (comment['id'] as num).toInt();
      _editingController.text = (comment['content'] ?? '').toString();
    });
  }

  Future<void> _submitEdit() async {
    final id = editingCommentId;
    if (id == null) return;
    final txt = _editingController.text.trim();
    if (txt.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('댓글을 입력하세요')));
      return;
    }
    setState(() => submittingEdit = true);
    try {
      final api = context.read<ApiClient>();                   // ✅ 토큰 자동 첨부
      await api.dio.put('/api/posts/${widget.postId}/comments/$id', data: {
        'content': txt,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('댓글 수정 완료')));
      setState(() => editingCommentId = null);
      await _loadComments();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.statusCode == 401
          ? '수정 실패: 로그인 후 다시 시도해 주세요 (401)'
          : '수정 실패 (${e.response?.statusCode ?? e.type}): ${e.response?.data ?? e.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => submittingEdit = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('정말 삭제하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final api = context.read<ApiClient>();                   // ✅ 토큰 자동 첨부
      await api.dio.delete('/api/posts/${widget.postId}/comments/$commentId');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제되었습니다')));
      await _loadComments();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.statusCode == 401
          ? '삭제 실패: 로그인 후 다시 시도해 주세요 (401)'
          : '삭제 실패 (${e.response?.statusCode ?? e.type}): ${e.response?.data ?? e.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _deletePost() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('게시물 삭제'),
        content: const Text('정말 게시물을 삭제하시겠습니까? (댓글도 삭제됩니다)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final api = context.read<ApiClient>();                   // ✅ 토큰 자동 첨부
      await api.dio.delete('/api/posts/${widget.postId}');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('게시물이 삭제되었습니다')));
      Navigator.of(context).pop('deleted');                    // 목록 새로고침 신호
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.statusCode == 401
          ? '삭제 실패: 로그인 후 다시 시도해 주세요 (401)'
          : '삭제 실패 (${e.response?.statusCode ?? e.type}): ${e.response?.data ?? e.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상세'),
        actions: [
          IconButton(
            tooltip: '삭제',
            icon: const Icon(Icons.delete),
            onPressed: loadingPost ? null : _deletePost,
          ),
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: loadingPost
          ? const Center(child: CircularProgressIndicator())
          : postError != null
          ? Center(child: Text('게시물 불러오기 오류: $postError'))
          : Column(
        children: [
          // Post content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post!['title'] ?? '',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(post!['content'] ?? ''),
                const SizedBox(height: 8),
                Text(
                  '작성자: ${post!['memberId'] ?? '-'} · ${post!['createdAt'] ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments header
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('댓글',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${comments.length}'),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: loadingComments
                ? const Center(child: CircularProgressIndicator())
                : commentsError != null
                ? Center(
                child: Text('댓글 불러오기 오류: $commentsError'))
                : comments.isEmpty
                ? RefreshIndicator(
              onRefresh: _loadComments,
              child: ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(
                      child:
                      Text('등록된 댓글이 없습니다')),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadComments,
              child: ListView.separated(
                itemCount: comments.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = comments[i];
                  final cid =
                  (c['id'] as num).toInt();
                  final content =
                  (c['content'] ?? '').toString();
                  final isEditing =
                      editingCommentId == cid;

                  return ListTile(
                    title: isEditing
                        ? TextField(
                      controller:
                      _editingController,
                      decoration:
                      const InputDecoration(
                          hintText: '댓글 수정'),
                      maxLines: null,
                    )
                        : Text(content),
                    subtitle: Text(
                        '${c['createdAt'] ?? ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isEditing)
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 20),
                            onPressed: () =>
                                _startEdit(c),
                            tooltip: '수정',
                          ),
                        if (isEditing)
                          IconButton(
                            icon: submittingEdit
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                              CircularProgressIndicator(
                                  strokeWidth:
                                  2),
                            )
                                : const Icon(Icons.check,
                                size: 20),
                            onPressed: submittingEdit
                                ? null
                                : _submitEdit,
                            tooltip: '저장',
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 20),
                          onPressed: () =>
                              _deleteComment(cid),
                          tooltip: '삭제',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Comment input
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                          hintText: '댓글을 입력하세요'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                    submittingComment ? null : _submitComment,
                    child: submittingComment
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('작성'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
