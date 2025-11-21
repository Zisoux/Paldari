// lib/screens/new_post_screen.dart
import 'dart:convert';
// import 'dart:io'; // 사용하지 않아서 주석 처리 (원하면 그대로 둬도 됨)

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../services/api.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // AuthState
import '../config.dart'; // apiBase 정의 (예: http://127.0.0.1:8080)

class NewPostScreen extends StatefulWidget {
  // 🔹 새 글 / 수정 공용
  final int? postId; // 수정 시 필요
  final Map<String, dynamic>? existingPost; // 수정 시 기존 데이터

  final String? initialCountry;
  final String? initialCategory;
  final String? initialLanguage; // '전체' | '한국어' | '영어' ... (라벨 또는 코드)
  final String? initialPersona; // '전체' | '내국인' | '외국인'

  final bool isEdit; // true면 수정 모드

  const NewPostScreen({
    Key? key,
    this.postId,
    this.existingPost,
    this.initialCountry,
    this.initialCategory,
    this.initialLanguage,
    this.initialPersona,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  final api = ApiService();
  bool submitting = false;

  // ── 국가 리스트 ─────────────────────────────────────────────────────────
  final List<String> countries = const [
    '말레이시아',
    '한국',
    '일본',
    '미국',
    '캐나다',
    '호주',
    '영국',
    '독일',
    '프랑스',
  ];

  // ── 카테고리, 내/외국인 ─────────────────────────────────────────────────
  final List<String> categories = const ['전체', '생활', '학업', '지역', '안전', '취업'];
  final List<String> personas = const ['전체', '내국인', '외국인'];

  // ── ✅ 전역 고정 언어 목록(라벨/코드) ───────────────────────────────────
  static const List<Map<String, String>> kLanguages = [
    {'label': '전체', 'code': 'all'},
    {'label': '한국어', 'code': 'ko'},
    {'label': '영어', 'code': 'en'},
    {'label': '일본어', 'code': 'ja'},
    {'label': '말레이어', 'code': 'ms'},
    {'label': '중국어', 'code': 'zh'},
    {'label': '프랑스어', 'code': 'fr'},
    {'label': '독일어', 'code': 'de'},
  ];

  // ── 선택값 상태 ─────────────────────────────────────────────────────────
  late String selectedCountry;
  late String selectedCategory;
  late String selectedLanguageCode; // ✅ 언어는 코드로 관리 ('all'|'ko'|...)
  late String selectedPersona;

  // ── 기존 첨부파일 상태 (수정 모드 전용) ─────────────────────────────────
  List<Map<String, dynamic>> existingAttachments = [];

  // ── 새로 선택한 업로드 파일 상태 ────────────────────────────────────────
  List<PlatformFile> selectedFiles = [];

  // ── 스타일 토큰 ────────────────────────────────────────────────────────
  static const hdr = Color(0xFFFFF7F1);
  static const chipBg = Color(0xFFF2F2F2);
  static const brand = Color(0xFFFAAD55);
  static const darkTab = Color(0xFF260101);
  static const borderColor = Color(0xFFF29D52);
  static const titlePal = Color(0xFF734124);
  static const titleDari = Color(0xFF260101);

  @override
  void initState() {
    super.initState();

    // 🔹 기본값 세팅(새 글 기준)
    selectedCountry = widget.initialCountry ?? '한국';
    selectedCategory = widget.initialCategory ?? '전체';
    selectedLanguageCode =
        _langCodeFromLabelOrCode(widget.initialLanguage) ?? 'all';
    selectedPersona = widget.initialPersona ?? '전체';

    // 🔹 수정 모드면 existingPost 값으로 덮어쓰기
    if (widget.isEdit && widget.existingPost != null) {
      final p = widget.existingPost!;

      _titleCtrl.text = (p['title'] ?? '').toString();
      _contentCtrl.text = (p['content'] ?? '').toString();

      selectedCountry = (p['country'] ?? selectedCountry).toString();
      selectedCategory = (p['category'] ?? selectedCategory).toString();

      // language: 코드/라벨 어떤 형식이 와도 처리
      final langFromPost =
      _langCodeFromLabelOrCode(p['language']?.toString());
      if (langFromPost != null) {
        selectedLanguageCode = langFromPost;
      }

      // persona / isForeigner → 내국인/외국인/전체
      final personaFromPost = p['persona']?.toString();
      final isForeigner = p['isForeigner'] as bool?;
      String personaValue;
      if (personaFromPost == '내국인' || personaFromPost == '외국인') {
        personaValue = personaFromPost!;
      } else if (isForeigner == true) {
        personaValue = '외국인';
      } else if (isForeigner == false) {
        personaValue = '내국인';
      } else {
        personaValue = selectedPersona;
      }
      selectedPersona = personaValue;

      // 🔹 기존 첨부파일 목록 세팅 (attachments: [{id, url, originalName}, ...])
      final rawAtt = p['attachments'];
      if (rawAtt is List) {
        existingAttachments = rawAtt
            .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ── 라벨/코드 헬퍼 ──────────────────────────────────────────────────────
  String? _langCodeFromLabelOrCode(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final s = v.trim();

    const codes = {'all', 'ko', 'en', 'ja', 'ms', 'zh', 'fr', 'de'};
    if (codes.contains(s.toLowerCase())) return s.toLowerCase();

    for (final e in kLanguages) {
      if (e['label'] == s) return e['code'];
    }
    switch (s.toLowerCase()) {
      case 'korean':
      case 'kr':
      case 'ko-kr':
        return 'ko';
      case 'english':
      case 'en-us':
      case 'en-uk':
        return 'en';
      case 'japanese':
      case 'jp':
      case 'ja-jp':
        return 'ja';
      case 'malay':
      case 'ms-my':
        return 'ms';
      case 'chinese':
      case 'zh-cn':
      case 'zh-tw':
        return 'zh';
      case 'french':
      case 'fr-fr':
        return 'fr';
      case 'german':
      case 'de-de':
        return 'de';
      case '전체':
        return 'all';
    }
    return null;
  }

  String _langLabelOf(String code) {
    final m = kLanguages.firstWhere(
          (e) => e['code'] == code,
      orElse: () => const {'label': '전체', 'code': 'all'},
    );
    return m['label']!;
  }

  // ── 🔥 파일 선택: "이미지 파일만" 허용 ───────────────────────────────────
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: [
        'png',
        'jpg',
        'jpeg',
        'gif',
        'webp',
      ], // 🔥 이미지 확장자만 허용
    );

    if (result == null) return;

    // 혹시 환경에 따라 이상한 확장자가 들어와도 한 번 더 필터링
    final validExt = ['png', 'jpg', 'jpeg', 'gif', 'webp'];
    final filtered = result.files.where((f) {
      final ext = f.extension?.toLowerCase();
      return validExt.contains(ext);
    }).toList();

    if (filtered.length != result.files.length) {
      // 비이미지 파일이 섞여있으면 자동제거 + 안내
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 파일만 선택할 수 있습니다.')),
      );
    }

    setState(() => selectedFiles = filtered);
  }

  void _clearFiles() {
    setState(() => selectedFiles = []);
  }

  // ── 기존 첨부파일 삭제 (API 바로 호출) ───────────────────────────────────
  Future<void> _deleteExistingAttachment(int attachmentId) async {
    if (!widget.isEdit || widget.postId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('첨부파일 삭제'),
        content: const Text('이 파일을 삭제하시겠어요?'),
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

    if (ok != true) return;

    try {
      await api.deleteAttachment(widget.postId!, attachmentId);
      if (!mounted) return;
      setState(() {
        existingAttachments.removeWhere(
              (att) => (att['id'] as num?)?.toInt() == attachmentId,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('첨부파일이 삭제되었습니다')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('첨부파일 삭제 실패: $e')),
      );
    }
  }

  // ── 파일 업로드 (게시 후 첨부 업로드 2단계) ─────────────────────────────
  Future<void> _uploadAttachments(int postId) async {
    if (selectedFiles.isEmpty) return;

    final uri = Uri.parse('$apiBase/api/posts/$postId/upload'); // 백엔드 업로드 엔드포인트
    final req = http.MultipartRequest('POST', uri);

    // 🔐 JWT 붙이기: AuthState에서 토큰 가져오기
    final auth = context.read<AuthState>();
    final token = await auth.pickAccessToken(); // auth_provider.dart에 정의된 메서드
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    req.headers['Accept'] = 'application/json';

    for (final f in selectedFiles) {
      http.MultipartFile part;
      if (f.bytes != null) {
        final mime = _guessMime(f.name);
        part = http.MultipartFile.fromBytes(
          'files',
          f.bytes!,
          filename: f.name,
          contentType: mime != null ? MediaType.parse(mime) : null,
        );
      } else if (f.path != null) {
        part = await http.MultipartFile.fromPath(
          'files',
          f.path!,
          filename: f.name,
          contentType: _guessMime(f.name) != null
              ? MediaType.parse(_guessMime(f.name)!)
              : null,
        );
      } else {
        continue;
      }
      req.files.add(part);
    }

    final resp = await req.send();
    final body = await resp.stream.bytesToString();
    if (resp.statusCode != 200) {
      throw Exception('첨부 업로드 실패: ${resp.statusCode} $body');
    }
  }

  // 🔥 이제는 이미지 MIME 타입만 반환
  String? _guessMime(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  String _fmtSize(int? bytes) {
    if (bytes == null) return '';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (submitting) return;

    setState(() => submitting = true);
    try {
      final Map<String, dynamic> payload = {
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'country': selectedCountry,
        'category': selectedCategory,
        'language':
        selectedLanguageCode == 'all' ? null : selectedLanguageCode,
        'isForeigner': selectedPersona == '외국인'
            ? true
            : (selectedPersona == '내국인' ? false : null),
        'persona': selectedPersona == '전체' ? null : selectedPersona,
      }..removeWhere((k, v) => v == null);

      if (widget.isEdit && widget.postId != null) {
        // 🔹 수정 모드: PUT /api/posts/{id}
        final updated = await api.updatePost(
          id: widget.postId!,
          title: payload['title'] as String,
          content: payload['content'] as String,
          country: payload['country'] as String?,
          category: payload['category'] as String?,
          language: payload['language'] as String?,
          isForeigner: payload['isForeigner'] as bool?,
          persona: payload['persona'] as String?,
        );
        final updatedId = (updated['id'] as num).toInt();

        // (선택) 새로 첨부한 파일이 있다면 추가 업로드
        await _uploadAttachments(updatedId);

        if (!mounted) return;
        Navigator.of(context).pop<int>(updatedId);
      } else {
        // 🔹 새 글 작성 모드: POST /api/posts
        final created = await api.createPost(
          title: payload['title'] as String,
          content: payload['content'] as String,
          country: payload['country'] as String?,
          category: payload['category'] as String?,
          language: payload['language'] as String?,
          isForeigner: payload['isForeigner'] as bool?,
          persona: payload['persona'] as String?,
        );
        final createdId = (created['id'] as num).toInt();

        // 2) 첨부 업로드(선택)
        await _uploadAttachments(createdId);

        if (!mounted) return;
        Navigator.of(context).pop<int>(createdId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;

    return Scaffold(
      backgroundColor: hdr,
      appBar: AppBar(
        backgroundColor: hdr,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Pal',
                style: TextStyle(
                  color: _NewPostScreenState.titlePal,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const TextSpan(
                text: 'Dari',
                style: TextStyle(
                  color: _NewPostScreenState.titleDari,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: isEdit ? '  수정' : '  글쓰기',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: submitting,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ── 메타 영역 ───────────────────────────────────────────
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('게시글 정보'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _DropdownField(
                                label: '국가',
                                value: selectedCountry,
                                items: countries,
                                onChanged: (v) =>
                                    setState(() => selectedCountry = v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DropdownField(
                                label: '카테고리',
                                value: selectedCategory,
                                items: categories,
                                onChanged: (v) =>
                                    setState(() => selectedCategory = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // 언어 선택
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('언어'),
                                  const SizedBox(height: 6),
                                  DropdownButtonHideUnderline(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: _PostsTokens.chipBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: DropdownButton<String>(
                                        value: selectedLanguageCode,
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        icon: const Icon(Icons.expand_more,
                                            size: 20, color: Colors.black87),
                                        items: kLanguages
                                            .map(
                                              (e) =>
                                              DropdownMenuItem<String>(
                                                value: e['code'],
                                                child: Text(
                                                  e['label']!,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                        )
                                            .toList(),
                                        onChanged: (code) {
                                          if (code == null) return;
                                          setState(
                                                  () => selectedLanguageCode = code);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PersonaSegment(
                                label: '내/외국인',
                                value: selectedPersona,
                                options: personas,
                                onChanged: (v) =>
                                    setState(() => selectedPersona = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── 제목/내용 입력 ───────────────────────────────────────
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('제목'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: _inputDecoration('제목을 입력하세요'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return '제목을 입력하세요';
                            }
                            if (v.trim().length < 2) {
                              return '제목은 2자 이상 입력하세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const _FieldLabel('내용'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _contentCtrl,
                          maxLines: 8,
                          decoration: _inputDecoration('내용을 입력하세요'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return '내용을 입력하세요';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── 첨부파일 섹션 ───────────────────────────────────────
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('첨부파일'),
                        const SizedBox(height: 8),

                        // 🔹 수정 모드일 때 기존 첨부파일 목록
                        if (widget.isEdit &&
                            existingAttachments.isNotEmpty) ...[
                          const Text(
                            '기존 첨부파일',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: existingAttachments.map((att) {
                              final id =
                                  (att['id'] as num?)?.toInt() ?? 0;
                              final name =
                                  att['originalName']?.toString() ??
                                      '첨부파일';
                              return Container(
                                margin:
                                const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFEAEAEA),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.insert_drive_file_rounded,
                                      size: 20,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        name,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () =>
                                          _deleteExistingAttachment(
                                              id),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 🔹 새로 선택할 첨부파일 영역
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickFiles,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brand,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              icon: const Icon(Icons.attach_file_rounded),
                              label: const Text('파일 선택'),
                            ),
                            const SizedBox(width: 8),
                            if (selectedFiles.isNotEmpty)
                              TextButton.icon(
                                onPressed: _clearFiles,
                                icon: const Icon(Icons.clear),
                                label: const Text('비우기'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (selectedFiles.isEmpty)
                          const Text(
                            '새로 추가할 파일이 없습니다.',
                            style: TextStyle(color: Colors.black54),
                          )
                        else
                          Column(
                            children: selectedFiles.map((f) {
                              final isImage = [
                                'png',
                                'jpg',
                                'jpeg',
                                'gif',
                                'webp'
                              ].contains(f.extension?.toLowerCase());
                              return Container(
                                margin:
                                const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFEAEAEA),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isImage
                                          ? Icons.image_rounded
                                          : Icons
                                          .insert_drive_file_rounded,
                                      size: 20,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        f.name,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _fmtSize(f.size),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── 제출 버튼 ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: submitting
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        submitting
                            ? (isEdit ? '저장 중...' : '등록 중...')
                            : (isEdit ? '수정하기' : '등록하기'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: brand, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

/// 라벨 텍스트 위젯
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }
}

/// 카드 컨테이너
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 공통 드롭다운
class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _PostsTokens.chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: value,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.expand_more,
                  size: 20, color: Colors.black87),
              items: items
                  .map(
                    (c) => DropdownMenuItem<String>(
                  value: c,
                  child: Text(
                    c,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// 내/외국인 세그먼트
class _PersonaSegment extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _PersonaSegment({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _PostsTokens.chipBg,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: options.map((g) {
              final selected = g == value;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(g),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? _PostsTokens.darkTab
                          : Colors.transparent,
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
        ),
      ],
    );
  }
}

/// Posts 화면과 공유하는 컬러 토큰
class _PostsTokens {
  static const chipBg = Color(0xFFF2F2F2);
  static const darkTab = Color(0xFF260101);
}
