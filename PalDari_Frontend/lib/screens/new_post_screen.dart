import 'package:flutter/material.dart';
import '../services/api.dart';
import '../config.dart'; // apiBase 등을 쓰는 프로젝트라면 유지, 아니면 제거해도 됨.

class NewPostScreen extends StatefulWidget {
  final String? initialCountry;
  final String? initialCategory;
  final String? initialLanguage; // '전체' | '한국어' | ...
  final String? initialPersona;  // '전체' | '내국인' | '외국인'

  const NewPostScreen({
    Key? key,
    this.initialCountry,
    this.initialCategory,
    this.initialLanguage,
    this.initialPersona,
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

  // ── 국가 리스트(요청 반영) ─────────────────────────────────────────────
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

  // ── 카테고리, 내/외국인 ────────────────────────────────────────────────
  final List<String> categories = const ['전체', '생활', '학업', '지역', '안전', '취업'];
  final List<String> personas = const ['전체', '내국인', '외국인'];

  // ── 국가별 언어 옵션(공식/주요 사용 언어 위주) ─────────────────────────
  // 필요 시 세부 지역(웨일스어 등) 확장 가능. 지금은 실용적으로 구성.
  final Map<String, List<String>> countryLanguages = const {
    '말레이시아': ['말레이어', '영어'],
    '한국': ['한국어'],
    '일본': ['일본어'],
    '미국': ['영어'],
    '캐나다': ['영어', '프랑스어'],
    '호주': ['영어'],
    '영국': ['영어'],
    '독일': ['독일어'],
    '프랑스': ['프랑스어'],
  };

  // ── 선택값 상태 ─────────────────────────────────────────────────────────
  late String selectedCountry;
  late String selectedCategory;
  late String selectedLanguage; // ← 국가별 옵션에 종속
  late String selectedPersona;

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
    selectedCountry  = widget.initialCountry  ?? '한국';
    selectedCategory = widget.initialCategory ?? '전체';
    selectedLanguage = widget.initialLanguage ?? '전체';
    selectedPersona  = widget.initialPersona  ?? '전체';
    _syncLanguageWithCountry(); // 초기 동기화
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ── 현재 국가에 맞춘 언어 옵션 반환(항상 '전체' 포함) ───────────────────
  List<String> get _languageOptionsForSelectedCountry {
    final langs = countryLanguages[selectedCountry] ?? const <String>[];
    // 중복 제거 + '전체'를 맨 앞에
    final unique = <String>{...langs}.toList();
    return ['전체', ...unique];
  }

  // 국가 변경/초기화 시, 현재 선택 언어가 옵션에 없으면 '전체'로 보정
  void _syncLanguageWithCountry() {
    final options = _languageOptionsForSelectedCountry;
    if (!options.contains(selectedLanguage)) {
      selectedLanguage = '전체';
    }
  }

  // 언어 코드 매핑 (서버가 코드값 선호 시 사용)
  String? _langCode(String v) {
    switch (v) {
      case '한국어': return 'ko';
      case '영어': return 'en';
      case '일본어': return 'ja';
      case '말레이어': return 'ms';
      case '중국어': return 'zh';
      case '프랑스어': return 'fr';
      case '독일어': return 'de';
      default: return null; // '전체'
    }
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
        'language': selectedLanguage == '전체'
            ? null
            : (_langCode(selectedLanguage) ?? selectedLanguage),
        'isForeigner': selectedPersona == '외국인'
            ? true
            : (selectedPersona == '내국인' ? false : null),
        'persona': selectedPersona == '전체' ? null : selectedPersona,
      }..removeWhere((k, v) => v == null);

      // ApiService가 (title, content, country, category)만 받는다고 가정
      final created = await api.createPost(
        title: payload['title'] as String,
        content: payload['content'] as String,
        country: payload['country'] as String?,
        category: payload['category'] as String?,
        // 서버/DTO 확장 시 아래 주석 해제
        // language: payload['language'] as String?,
        // isForeigner: payload['isForeigner'] as bool?,
        // persona: payload['persona'] as String?,
      );

      final createdId = (created['id'] as num).toInt();
      if (!mounted) return;
      Navigator.of(context).pop<int>(createdId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등록 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              TextSpan(
                text: 'Pal',
                style: const TextStyle(
                  color: _NewPostScreenState.titlePal,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'Dari',
                style: const TextStyle(
                  color: _NewPostScreenState.titleDari,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
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
                                onChanged: (v) {
                                  setState(() {
                                    selectedCountry = v!;
                                    _syncLanguageWithCountry();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DropdownField(
                                label: '카테고리',
                                value: selectedCategory,
                                items: categories,
                                onChanged: (v) => setState(() => selectedCategory = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _DropdownField(
                                label: '언어',
                                value: selectedLanguage,
                                items: _languageOptionsForSelectedCountry,
                                onChanged: (v) => setState(() => selectedLanguage = v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PersonaSegment(
                                label: '내/외국인',
                                value: selectedPersona,
                                options: personas,
                                onChanged: (v) => setState(() => selectedPersona = v),
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
                            if (v == null || v.trim().isEmpty) return '제목을 입력하세요';
                            if (v.trim().length < 2) return '제목은 2자 이상 입력하세요';
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
                            if (v == null || v.trim().isEmpty) return '내용을 입력하세요';
                            return null;
                          },
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: submitting
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        submitting ? '등록 중...' : '등록하기',
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87),
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
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))],
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
          child: Container
            (
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _PostsTokens.chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: value,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.expand_more, size: 20, color: Colors.black87),
              items: items
                  .map(
                    (c) => DropdownMenuItem<String>(
                  value: c,
                  child: Text(
                    c,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
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
          decoration: BoxDecoration(color: _PostsTokens.chipBg, borderRadius: BorderRadius.circular(12)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? _PostsTokens.darkTab : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      g,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF595959),
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
