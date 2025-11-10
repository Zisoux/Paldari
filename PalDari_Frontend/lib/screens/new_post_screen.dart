import 'package:flutter/material.dart';
import '../services/api.dart';

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

  late TextEditingController _countryCtrl;
  late TextEditingController _categoryCtrl;

  bool submitting = false;
  final api = ApiService();

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
      final created = await api.createPost(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        country: _countryCtrl.text.trim().isEmpty
            ? null
            : _countryCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
      );

      final createdId = (created['id'] as num).toInt();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작성 완료')),
      );

      // PostsScreen에서 createdId 받아서 상세로 이동
      Navigator.of(context).pop(createdId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('작성 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
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
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: '제목'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
              ),
              const SizedBox(height: 12),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      ? const CircularProgressIndicator(color: Colors.white)
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
