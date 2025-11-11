import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/pal_bottom_nav.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final _tagController = TextEditingController();
  final _regionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 태그/지역 최신화 (조용히 실패 무시)
    // addPostFrameCallback 써서 빌드 전에 read 에러 안 나게
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthState>();
      auth.reloadTags();
      auth.reloadRegions();
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const maxContentWidth = 480.0;
    final auth = context.watch<AuthState>();

    final username = (auth.profile?['username'] as String?) ?? 'User';
    final email = (auth.profile?['email'] as String?) ?? '';
    final initial =
    username.isNotEmpty ? username[0].toUpperCase() : 'U';

    // 혹시라도 auth.tags / regions 가 null인 구현이 남아있다면 방어
    final List<String> tags =
    (auth.tags is List<String>) ? auth.tags : const <String>[];
    final List<String> regions =
    (auth.regions is List<String>) ? auth.regions : const <String>[];

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
      bottomNavigationBar: const PalBottomNav(currentIndex: 4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double contentWidth =
            constraints.maxWidth > maxContentWidth
                ? maxContentWidth
                : constraints.maxWidth;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 프로필 헤더
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
                              Text(
                                initial,
                                style: const TextStyle(
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
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () {
                                    // TODO: 배경 변경
                                  },
                                  child: Text(
                                    '배경 변경',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black.withOpacity(0.5),
                                      decoration:
                                      TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, '/settings');
                            },
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 평점 카드 (목업)
                      const _SectionCard(
                        title: '평점',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.end,
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
                            _RatingBarRow(
                                star: 5, count: 18, ratio: 1.0),
                            _RatingBarRow(
                                star: 4, count: 0, ratio: 0.0),
                            _RatingBarRow(
                                star: 3, count: 0, ratio: 0.0),
                            _RatingBarRow(
                                star: 2, count: 0, ratio: 0.0),
                            _RatingBarRow(
                                star: 1, count: 0, ratio: 0.0),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 태그 카드
                      _SectionCard(
                        title: '태그',
                        trailing: Text(
                          '${tags.length}/5',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in tags)
                              _TagChip(
                                label: t,
                                onDelete: () => context
                                    .read<AuthState>()
                                    .removeTag(t),
                              ),
                            if (tags.length < 5)
                              _AddChip(
                                hint: '#태그 추가',
                                controller: _tagController,
                                onSubmitted: (text) async {
                                  final v = text.trim();
                                  if (v.isEmpty) return;
                                  await context
                                      .read<AuthState>()
                                      .addTag(v);
                                },
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 지역 카드
                      _SectionCard(
                        title: '지역',
                        trailing: Text(
                          '${regions.length}/5',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final r in regions)
                              _TagChip(
                                label: r,
                                onDelete: () => context
                                    .read<AuthState>()
                                    .removeRegion(r),
                              ),
                            if (regions.length < 5)
                              _AddChip(
                                hint: '#지역 추가',
                                controller: _regionController,
                                onSubmitted: (text) async {
                                  final v = text.trim();
                                  if (v.isEmpty) return;
                                  await context
                                      .read<AuthState>()
                                      .addRegion(v);
                                },
                              ),
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

// 공통 섹션 카드
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
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
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
  final VoidCallback onDelete;

  const _TagChip({
    required this.label,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: const Color(0x7FF39D52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.black.withOpacity(0.3),
          width: 0.6,
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
    );
  }
}

// 입력 칩 (엔터 + 플러스 둘 다 동작)
class _AddChip extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final Future<void> Function(String) onSubmitted;

  const _AddChip({
    required this.hint,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 11),
              onSubmitted: (v) async {
                final text = v.trim();
                if (text.isEmpty) return;
                await onSubmitted(text);
                controller.clear();
              },
            ),
          ),
          InkWell(
            child: const Icon(Icons.add, size: 16),
            onTap: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              await onSubmitted(text);
              controller.clear();
            },
          ),
        ],
      ),
    );
  }
}

// 평점 바 (목업)
class _RatingBarRow extends StatelessWidget {
  final int star;
  final int count;
  final double ratio;

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
