import 'package:flutter/material.dart';
import '../widgets/pal_bottom_nav.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 넓은 화면(웹)에서 너무 퍼지지 않도록 최대 폭 제한 (모바일 느낌 유지)
    const maxContentWidth = 480.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F1),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFF7F1),
        centerTitle: true,
        title: const Text(
          '마이페이지',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: const PalBottomNav(
        currentIndex: 4, // 마이페이지 탭
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 여기서 num 오류 안 나게 정확히 double로 처리
            final double contentWidth =
            constraints.maxWidth > maxContentWidth
                ? maxContentWidth
                : constraints.maxWidth;

            return Center(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: contentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 프로필 영역
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFF39D52),
                                    width: 4,
                                  ),
                                  color: const Color(0xFF2C2C2C),
                                ),
                              ),
                              const Text(
                                'N',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nur',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '123456789@malay...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () {
                                    // TODO: 배경 변경 액션
                                  },
                                  child: Text(
                                    '배경 변경',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black.withOpacity(0.5),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // TODO: 설정 화면 이동 등
                            },
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 평점 카드
                      const _SectionCard(
                        title: '평점',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '5.0',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '/ 5',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '(18)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _RatingBarRow(star: 5, count: 18, ratio: 1.0),
                            _RatingBarRow(star: 4, count: 0, ratio: 0.0),
                            _RatingBarRow(star: 3, count: 0, ratio: 0.0),
                            _RatingBarRow(star: 2, count: 0, ratio: 0.0),
                            _RatingBarRow(star: 1, count: 0, ratio: 0.0),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 태그 카드
                      const _SectionCard(
                        title: '태그',
                        trailing: Text(
                          '5/5',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _TagChip('#생활'),
                            _TagChip('#지역'),
                            _TagChip('#취업'),
                            _TagChip('#학업'),
                            _TagChip('#안전'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 지역 카드
                      const _SectionCard(
                        title: '지역',
                        trailing: Text(
                          '2/5',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _TagChip('#쿠알라룸푸르'),
                            _TagChip('#코타키나발루'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// 공통 섹션 카드 위젯
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: trailing == null
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

// 태그 칩
class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x7FF39D52),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withOpacity(0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black,
        ),
      ),
    );
  }
}

// 평점 바 한 줄
class _RatingBarRow extends StatelessWidget {
  final int star;
  final int count;
  final double ratio; // 0.0 ~ 1.0

  const _RatingBarRow({
    required this.star,
    required this.count,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$star',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.star,
            size: 14,
            color: Color(0xFFF39D52),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDED),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF39D52),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
