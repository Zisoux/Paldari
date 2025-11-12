// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api.dart';

// ===== PalDari 톤 =====
const _bgHeader = Color(0xFFFFF7F1);
const _titlePal = Color(0xFF734124);
const _deepBrown = Color(0xFF260101);
const _hintGrey  = Color(0xFF9F9FA1);
const _chipGrey  = Color(0xFFF2F2F2);

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final api = ApiService();
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
      final p = await api.fetchPost(widget.postId);
      if (!mounted) return;
      setState(() {
        post = p;
      });
    } on DioException catch (e) {
      // ✅ 404면 이미 삭제된 게시글: 안내 후 목록으로 복귀 + 'deleted' 신호
      if (e.response?.statusCode == 404) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 삭제된 게시글입니다.')),
        );
        Navigator.of(context).pop('deleted');
        return;
      }
      if (!mounted) return;
      setState(() {
        postError = e.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        postError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingPost = false;
        });
      }
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      loadingComments = true;
      commentsError = null;
    });
    try {
      final list = await api.fetchComments(widget.postId);
      if (!mounted) return;
      setState(() {
        comments = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        commentsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingComments = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글을 입력하세요')));
      return;
    }
    setState(() => submittingComment = true);
    try {
      await api.createComment(widget.postId, content: text);
      _commentController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 작성 완료')));
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 작성 실패: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글을 입력하세요')));
      return;
    }
    setState(() => submittingEdit = true);
    try {
      await api.updateComment(widget.postId, id, content: txt);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 수정 완료')));
      setState(() => editingCommentId = null);
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 실패: $e')));
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
      await api.deleteComment(widget.postId, commentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다')));
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
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
      await api.deletePost(widget.postId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시물이 삭제되었습니다')));
      // ✅ 목록 화면이 새로고침하도록 'deleted'로 결과 전달
      Navigator.of(context).pop('deleted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  // ====== helper UI ======
  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first;
    return (parts.first.characters.first + parts.last.characters.first);
  }

  Widget _tagChips(dynamic tagsField) {
    if (tagsField is List && tagsField.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: -6,
        children: tagsField.map<Widget>((t) {
          final text = t.toString();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _chipGrey,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              text.startsWith('#') ? text : '#$text',
              style: const TextStyle(
                color: Color(0xFF595959),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121F2F) : Colors.white,
      appBar: AppBar(
        backgroundColor: _bgHeader,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _titlePal),
          onPressed: () => Navigator.pop(context),
          tooltip: '뒤로가기',
        ),
        centerTitle: true,
        title: const Text(
          '상세',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh, color: _titlePal),
            onPressed: _loadAll,
          ),
          IconButton(
            tooltip: '삭제',
            icon: const Icon(Icons.delete, color: _titlePal),
            onPressed: loadingPost ? null : _deletePost,
          ),
        ],
      ),
      body: loadingPost
          ? const Center(child: CircularProgressIndicator())
          : postError != null
          ? Center(child: Text('게시물 불러오기 오류: $postError'))
          : Column(
        children: [
          // ===== 게시글 카드 =====
          Card(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자/메타
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFF39D52),
                        child: Text(
                          _initials((post!['authorUsername'] ?? '').toString()),
                          style: const TextStyle(
                            color: _titlePal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (post!['authorUsername'] ?? '-').toString(),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              // createdAt은 서버 포맷 그대로 노출 (가공 원하면 파서 추가)
                              (post!['createdAt'] ?? '').toString(),
                              style: const TextStyle(
                                color: _hintGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 옵션 메뉴 필요 시 PopupMenuButton으로 확장
                      const SizedBox(width: 4),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 제목
                  Text(
                    (post!['title'] ?? '').toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 태그 섹션 (post['tags']가 List일 때)
                  _tagChips(post!['tags']),

                  if (post!['tags'] is List && (post!['tags'] as List).isNotEmpty)
                    const SizedBox(height: 10),

                  // 본문
                  Text(
                    (post!['content'] ?? '').toString(),
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          // ===== 댓글 헤더 =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('댓글', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${comments.length}', style: const TextStyle(color: _hintGrey)),
              ],
            ),
          ),
          const Divider(height: 1),

          // ===== 댓글 리스트 =====
          Expanded(
            child: loadingComments
                ? const Center(child: CircularProgressIndicator())
                : commentsError != null
                ? Center(child: Text('댓글 불러오기 오류: $commentsError'))
                : comments.isEmpty
                ? RefreshIndicator(
              onRefresh: _loadComments,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('등록된 댓글이 없습니다')),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadComments,
              child: ListView.separated(
                itemCount: comments.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = comments[i];
                  final cid = (c['id'] as num).toInt();
                  final content = (c['content'] ?? '').toString();
                  final isEditing = editingCommentId == cid;
                  final createdAt = (c['createdAt'] ?? '').toString();

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFF39D52),
                      child: Text(
                        _initials((c['authorUsername'] ?? 'U').toString()),
                        style: const TextStyle(
                          color: _titlePal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: isEditing
                        ? TextField(
                      controller: _editingController,
                      decoration: const InputDecoration(
                        hintText: '댓글 수정',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                    )
                        : Text(content),
                    subtitle: Text(createdAt, style: const TextStyle(fontSize: 12, color: _hintGrey)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isEditing)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _startEdit(c),
                            tooltip: '수정',
                          ),
                        if (isEditing)
                          IconButton(
                            icon: submittingEdit
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.check, size: 20),
                            onPressed: submittingEdit ? null : _submitEdit,
                            tooltip: '저장',
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _deleteComment(cid),
                          tooltip: '삭제',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ===== 댓글 입력 =====
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1B2A) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF1E2937) : const Color(0xFFECECEC),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: '댓글을 입력하세요',
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF162635) : const Color(0xFFFDFDFD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFECECEC)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFECECEC)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xCCFAAD55),
                      foregroundColor: _deepBrown,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: submittingComment ? null : _submitComment,
                    child: submittingComment
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
