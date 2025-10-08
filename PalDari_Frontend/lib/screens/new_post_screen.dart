import 'package:flutter/material.dart';
import '../services/api.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({Key? key}) : super(key: key);

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool submitting = false;
  final api = ApiService();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { submitting = true; });
    try {
      // 임시: memberId 고정(추후 인증 연동 후 실제 user id 사용)
      final created = await api.createPost(memberId: 1, title: _titleCtrl.text.trim(), content: _contentCtrl.text.trim());
      final createdId = (created['id'] as num).toInt();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('작성 완료')));
      // 상세로 바로 이동하려면 이 페이지에서 반환 값을 반환하거나 직접 push
      Navigator.of(context).pop(createdId); // PostsScreen이 createdId를 받고 상세로 이동함
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('작성 실패: $e')));
    } finally {
      if (mounted) setState(() { submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('새 글 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(labelText: '제목'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
              ),
              SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  controller: _contentCtrl,
                  decoration: InputDecoration(labelText: '내용'),
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? '내용을 입력하세요' : null,
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : _submit,
                  child: submitting ? CircularProgressIndicator(color: Colors.white) : Text('작성'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
