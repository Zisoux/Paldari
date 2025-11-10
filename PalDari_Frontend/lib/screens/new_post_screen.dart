import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart'; // ✅ ApiClient 사용 (Authorization 자동 첨부)

class NewPostScreen extends StatefulWidget {
  final String? initialCountry;
  final String? initialCategory;

  const NewPostScreen({
    Key? key,
    this.initialCountry,
    this.initialCategory,
  }) : super(key: key);

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  late final TextEditingController _countryCtrl;
  late final TextEditingController _categoryCtrl;

  bool submitting = false;

  @override
  void initState() {
    super.initState();
    _countryCtrl = TextEditingController(text: widget.initialCountry ?? '');
    _categoryCtrl = TextEditingController(text: widget.initialCategory ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _countryCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => submitting = true);
    try {
      // ✅ ApiClient는 Provider로 main에서 주입되어 있어야 합니다.
      final api = context.read<ApiClient>();

      // ⚠️ 현재 백엔드 스펙에 맞춰 최소값만 전송 (country/category는 추후 백엔드에 추가하면 같이 보냄)
      final resp = await api.dio.post(
        '/api/posts',
        data: {
          'memberId': 1, // TODO: 운영에선 토큰의 사용자로 서버에서 결정하도록 변경
          'title': _titleCtrl.text.trim(),
          'content': _contentCtrl.text.trim(),
          // 'country': _countryCtrl.text.trim(),
          // 'category': _categoryCtrl.text.trim(),
        },
      );

      final created = resp.data as Map<String, dynamic>;
      final createdId = (created['id'] as num).toInt();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작성 완료')),
      );
      // PostsScreen으로 id 반환 → 거기서 상세로 이동
      Navigator.of(context).pop(createdId);
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      // 401 등 오류 메시지 간단 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('작성 실패: $msg')),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 글 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 선택된 국가/카테고리 표시 (읽기 전용)
              TextFormField(
                controller: _countryCtrl,
                decoration: const InputDecoration(labelText: '국가'),
                readOnly: true,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: '카테고리'),
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // 제목
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: '제목'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
              ),
              const SizedBox(height: 12),

              // 내용(확장)
              Expanded(
                child: TextFormField(
                  controller: _contentCtrl,
                  decoration: const InputDecoration(labelText: '내용'),
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '내용을 입력하세요' : null,
                ),
              ),
              const SizedBox(height: 12),

              // 작성 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('작성'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
