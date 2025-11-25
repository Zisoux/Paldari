import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/star_rating.dart';

class BuddyRatingScreen extends StatefulWidget {
  /// ⭐ 평가받는 사람의 userId (users.id)
  ///   → 절대 memberId / roomMemberId 아님
  final int buddyId;

  /// 이 평점을 남기는 채팅방 id
  final int chatRoomId;

  final String buddyName;
  final String buddyImageUrl;
  final List<String> tags;


  const BuddyRatingScreen({
    Key? key,
    required this.buddyId,
    required this.chatRoomId,
    required this.buddyName,
    required this.buddyImageUrl,
    required this.tags,
  }) : super(key: key);

  @override
  State<BuddyRatingScreen> createState() => _BuddyRatingScreenState();
}

class _BuddyRatingScreenState extends State<BuddyRatingScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _commentCtrl = TextEditingController();

  int _score = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_score == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점을 선택해 주세요.')),
      );
      return;
    }
    // ⭐ 추가: 지금 넘기려는 buddyId / chatRoomId 확인
    debugPrint('[RATING] buddyId=${widget.buddyId}, chatRoomId=${widget.chatRoomId}');


    setState(() => _submitting = true);

    try {
      await _api.submitRating(
        buddyId: widget.buddyId,
        chatRoomId: widget.chatRoomId,
        score: _score,
        comment: _commentCtrl.text.trim().isEmpty
            ? null
            : _commentCtrl.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('평가가 저장되었습니다.')),
      );

      Navigator.of(context).pop(true); // 이전 화면으로, 필요하면 true 리턴
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('평가 저장 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F1),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFF7F1),
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Buddy 평가',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 프로필 이미지
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFFFC58F),
              backgroundImage:
              widget.buddyImageUrl.isNotEmpty ? NetworkImage(widget.buddyImageUrl) : null,
              child: widget.buddyImageUrl.isEmpty
                  ? Text(
                widget.buddyName.isNotEmpty
                    ? widget.buddyName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              widget.buddyName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // 매칭 태그 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6CDB7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '매칭 태그',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC58F),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#$t',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 평점 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6CDB7)),
              ),
              child: Column(
                children: [
                  const Text(
                    '평점',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StarRating(
                    value: _score,
                    onChanged: (v) => setState(() => _score = v),
                    size: 32,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 피드백 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6CDB7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '피드백 (선택사항)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Buddy에게 남기고 싶은 추가적인 피드백을 작성해 주세요.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE49B57),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text(
                  '평가 제출',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
