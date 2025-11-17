// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';
import '../config.dart'; // 🔥 apiBase 사용
import 'new_post_screen.dart';

// ===== PalDari 톤 =====
const _bgHeader = Color(0xFFFFF7F1);
const _titlePal = Color(0xFF734124);
const _deepBrown = Color(0xFF260101);
const _hintGrey = Color(0xFF9F9FA1);
const _chipGrey = Color(0xFFF2F2F2);

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

  final TextEditingController _commentController = TextEditingController();
  bool submittingComment = false;

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
      if (e.response?.statusCode == 404) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('이미 삭제된 게시글입니다.')));
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('댓글을 입력하세요')));
      return;
    }
    setState(() => submittingComment = true);
    try {
      await api.createComment(widget.postId, content: text);
      _commentController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('댓글 작성 완료')));
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('댓글 작성 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          submittingComment = false;
        });
      }
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
      await api.updateComment(widget.postId, id, content: txt);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('댓글 수정 완료')));
      setState(() => editingCommentId = null);
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('수정 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          submittingEdit = false;
        });
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('정말 삭제하시겠어요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await api.deleteComment(widget.postId, commentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제되었습니다')));
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  Future<void> _deletePost() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('게시물 삭제'),
        content: const Text('정말 게시물을 삭제하시겠습니까? (댓글도 삭제됩니다)'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await api.deletePost(widget.postId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('게시물이 삭제되었습니다')));
      Navigator.of(context).pop('deleted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  // =============================
  // 🔥 게시글 수정 화면으로 이동
  // =============================
  Future<void> _goToEdit() async {
    if (post == null) return;
    final id = (post!['id'] as num?)?.toInt() ?? widget.postId;

    final editedId = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => NewPostScreen(
          isEdit: true,
          postId: id,
          existingPost: post,
          initialCountry: post!['country']?.toString(),
          initialCategory: post!['category']?.toString(),
          initialLanguage: post!['language']?.toString(),
          initialPersona: post!['persona']?.toString(),
        ),
      ),
    );

    if (editedId != null) {
      // 수정 후 다시 불러오기
      await _loadPost();
      await _loadComments();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('게시글이 수정되었습니다.')));
    }
  }

  // =========================================
  // 🔥 첨부파일 섹션 (절대경로 + URL 인코딩 적용)
  // =========================================
  Widget _attachmentsSection() {
    final rawList = post?['attachments'];
    if (rawList is! List || rawList.isEmpty) {
      return const SizedBox.shrink();
    }

    final attachments = rawList
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          '첨부파일',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...attachments.map((att) {
          final url = att['url']?.toString() ?? '';
          final name = att['originalName']?.toString() ?? '';
          if (url.isEmpty) return const SizedBox.shrink();

          // 🔥 /uploads/... 상대경로 → 절대 URL
          String fullUrl = "$apiBase$url";

          // 🔥 한글/공백 URL 인코딩
          fullUrl = Uri.encodeFull(fullUrl);

          final lower = fullUrl.toLowerCase();
          final isImage = lower.endsWith('.png') ||
              lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.gif') ||
              lower.endsWith('.webp');

          if (isImage) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? '이미지 파일' : name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 350,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        fullUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // 🔗 일반 파일: 링크로 열기
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.attach_file),
            title: Text(
              name.isEmpty ? fullUrl : name,
              style: const TextStyle(
                decoration: TextDecoration.underline,
                fontSize: 14,
              ),
            ),
            onTap: () async {
              final uri = Uri.parse(fullUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          );
        }),
      ],
    );
  }

  // =========================================

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first;
    return parts.first.characters.first + parts.last.characters.first;
  }

  /// 언어 코드 → 보기 좋은 라벨
  String? _prettyLanguage(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    switch (s) {
      case 'ko':
        return '한국어';
      case 'en':
        return '영어';
      case 'ja':
        return '일본어';
      case 'ms':
        return '말레이어';
      case 'zh':
        return '중국어';
      case 'fr':
        return '프랑스어';
      case 'de':
        return '독일어';
      case 'all':
      case '전체':
        return '전체';
      default:
        return s; // 혹시 다른 문자열이면 그대로 노출
    }
  }

  /// country / category / language / persona 를 태그처럼 묶어서 보여주기
  Widget _metaChips() {
    if (post == null) return const SizedBox.shrink();

    final List<String> tags = [];

    final country = post!['country']?.toString();
    if (country != null && country.isNotEmpty) {
      tags.add(country);
    }

    final category = post!['category']?.toString();
    if (category != null && category.isNotEmpty && category != '전체') {
      tags.add(category);
    }

    final langLabel = _prettyLanguage(post!['language']);
    if (langLabel != null && langLabel.isNotEmpty && langLabel != '전체') {
      tags.add(langLabel);
    }

    final persona = post!['persona']?.toString();
    if (persona != null && persona.isNotEmpty && persona != '전체') {
      tags.add(persona);
    }

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: _tagChips(tags),
    );
  }

  Widget _tagChips(dynamic tagsField) {
    if (tagsField is List && tagsField.isNotEmpty) {
      return Wrap(
        spacing: 8,
        children: tagsField.map<Widget>((t) {
          final text = t.toString();
          return Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      backgroundColor:
      isDark ? const Color(0xFF121F2F) : Colors.white,
      appBar: AppBar(
        backgroundColor: _bgHeader,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _titlePal),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          '상세',
          style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _titlePal),
            onPressed: _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: _titlePal),
            onPressed: loadingPost ? null : _goToEdit,
          ),
          IconButton(
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
          // 🔹 위쪽 전체(게시글 + 댓글 리스트)를 스크롤 가능하게
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadComments,
              child: ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: [
                  // ── 게시글 카드 ───────────────────────────────
                  Card(
                    margin: const EdgeInsets.fromLTRB(
                        16, 14, 16, 10),
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding:
                      const EdgeInsets.fromLTRB(
                          16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                const Color(
                                    0xFFF39D52),
                                child: Text(
                                  _initials(
                                    (post!['author'] ??
                                        post![
                                        'authorUsername'] ??
                                        '')
                                        .toString(),
                                  ),
                                  style:
                                  const TextStyle(
                                    color: _titlePal,
                                    fontWeight:
                                    FontWeight
                                        .w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(
                                      (post!['author'] ??
                                          post![
                                          'authorUsername'] ??
                                          '-')
                                          .toString(),
                                      style:
                                      const TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                        FontWeight
                                            .w700,
                                      ),
                                    ),
                                    const SizedBox(
                                        height: 2),
                                    Text(
                                      (post!['createdAt'] ??
                                          '')
                                          .toString(),
                                      style:
                                      const TextStyle(
                                        color: _hintGrey,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            (post!['title'] ?? '')
                                .toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _metaChips(),
                          Text(
                            (post!['content'] ?? '')
                                .toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          _attachmentsSection(),
                        ],
                      ),
                    ),
                  ),

                  // ── 댓글 헤더 ────────────────────────────────
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                        16, 6, 16, 8),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        const Text(
                          '댓글',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold),
                        ),
                        Text(
                          '${comments.length}',
                          style: const TextStyle(
                              color: _hintGrey),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // ── 댓글 리스트/상태 ────────────────────────
                  if (loadingComments)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 40),
                      child: Center(
                        child:
                        CircularProgressIndicator(),
                      ),
                    )
                  else if (commentsError != null)
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(
                          vertical: 40),
                      child: Center(
                        child: Text(
                          '댓글 불러오기 오류: $commentsError',
                        ),
                      ),
                    )
                  else if (comments.isEmpty)
                      const Padding(
                        padding:
                        EdgeInsets.symmetric(
                            vertical: 40),
                        child: Center(
                          child: Text(
                            '등록된 댓글이 없습니다',
                          ),
                        ),
                      )
                    else
                      ...comments.map((c) {
                        final cid =
                        (c['id'] as num).toInt();
                        final content =
                        (c['content'] ?? '')
                            .toString();
                        final isEditing =
                            editingCommentId == cid;
                        final createdAt =
                        (c['createdAt'] ?? '')
                            .toString();

                        return Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                const Color(
                                    0xFFF39D52),
                                child: Text(
                                  _initials(
                                    (c['authorUsername'] ??
                                        'U')
                                        .toString(),
                                  ),
                                  style:
                                  const TextStyle(
                                    color: _titlePal,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ),
                              title: isEditing
                                  ? TextField(
                                controller:
                                _editingController,
                                decoration:
                                const InputDecoration(
                                  hintText: '댓글 수정',
                                  isDense: true,
                                  border:
                                  OutlineInputBorder(),
                                ),
                                maxLines: null,
                              )
                                  : Text(content),
                              subtitle: Text(
                                createdAt,
                                style:
                                const TextStyle(
                                  fontSize: 12,
                                  color: _hintGrey,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize:
                                MainAxisSize.min,
                                children: [
                                  if (!isEditing)
                                    IconButton(
                                      icon:
                                      const Icon(
                                        Icons.edit,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _startEdit(
                                              c),
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
                                          2,
                                        ),
                                      )
                                          : const Icon(
                                        Icons.check,
                                        size: 20,
                                      ),
                                      onPressed:
                                      submittingEdit
                                          ? null
                                          : _submitEdit,
                                    ),
                                  IconButton(
                                    icon:
                                    const Icon(
                                      Icons.delete,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _deleteComment(
                                            cid),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      }).toList(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // 🔹 아래 댓글 입력창 (고정)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                  12, 8, 12, 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F1B2A)
                    : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF1E2937)
                        : const Color(0xFFECECEC),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                      _commentController,
                      decoration:
                      InputDecoration(
                        hintText: '댓글을 입력하세요',
                        isDense: true,
                        filled: true,
                        fillColor: isDark
                            ? const Color(
                            0xFF162635)
                            : const Color(
                            0xFFFDFDFD),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(12),
                          borderSide:
                          const BorderSide(
                            color:
                            Color(0xFFECECEC),
                          ),
                        ),
                        enabledBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(12),
                          borderSide:
                          const BorderSide(
                            color:
                            Color(0xFFECECEC),
                          ),
                        ),
                        contentPadding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style:
                    FilledButton.styleFrom(
                      backgroundColor:
                      const Color(
                          0xCCFAAD55),
                      foregroundColor:
                      _deepBrown,
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(12),
                      ),
                    ),
                    onPressed:
                    submittingComment
                        ? null
                        : _submitComment,
                    child: submittingComment
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
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
