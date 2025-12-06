import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/pal_bottom_nav.dart';
import '../services/api.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final ApiService _api = ApiService();

  // ⭐ 평점 요약 상태
  bool _ratingLoading = true;
  String? _ratingError;
  double _ratingAverage = 0.0;
  int _ratingTotalCount = 0;
  int _count1 = 0;
  int _count2 = 0;
  int _count3 = 0;
  int _count4 = 0;
  int _count5 = 0;

  // ✅ EditProfileScreen과 동일하게 태그 코드 → 라벨 매핑
  static const Map<String, String> _tagOptions = {
    'LIFE': '생활',
    'STUDY': '학업',
    'REGION': '지역',
    'JOB': '취업',
    'SAFETY': '안전',
  };

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 태그/지역 + 평점 요약 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthState>();
      auth.reloadTags();
      auth.reloadRegions();
      _loadRatingSummary();
    });
  }

  Future<void> _loadRatingSummary() async {
    setState(() {
      _ratingLoading = true;
      _ratingError = null;
    });

    try {
      final data = await _api.fetchMyRatingSummary();

      final avg = (data['average'] as num?)?.toDouble() ?? 0.0;
      final total = (data['totalCount'] as num?)?.toInt() ?? 0;

      setState(() {
        _ratingAverage = avg;
        _ratingTotalCount = total;
        _count1 = (data['count1'] as num?)?.toInt() ?? 0;
        _count2 = (data['count2'] as num?)?.toInt() ?? 0;
        _count3 = (data['count3'] as num?)?.toInt() ?? 0;
        _count4 = (data['count4'] as num?)?.toInt() ?? 0;
        _count5 = (data['count5'] as num?)?.toInt() ?? 0;
        _ratingLoading = false;
      });
    } catch (e) {
      setState(() {
        _ratingError = '평점을 불러오지 못했습니다.';
        _ratingLoading = false;
      });
    }
  }

  // 태그 코드/라벨 섞여 있어도 항상 한글 라벨로 보여주기
  String _displayTagLabel(String raw) {
    // 코드(LIFE 등)로 온 경우
    if (_tagOptions.containsKey(raw)) {
      return _tagOptions[raw]!;
    }
    // 이미 라벨(생활 등)로 온 경우도 그대로 허용
    final found = _tagOptions.entries.firstWhere(
          (e) => e.value == raw,
      orElse: () => const MapEntry('', ''),
    );
    if (found.key.isNotEmpty) {
      return found.value;
    }
    // 매핑 안 되면 원문 그대로 노출
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    const maxContentWidth = 480.0;
    final auth = context.watch<AuthState>();

    final username = (auth.profile?['username'] as String?) ?? 'User';
    final email = (auth.profile?['email'] as String?) ?? '';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

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
            final double contentWidth = constraints.maxWidth > maxContentWidth
                ? maxContentWidth
                : constraints.maxWidth;

            return Center(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                    Navigator.pushNamed(
                                        context, '/editProfile');
                                  },
                                  child: Text(
                                    '내 정보 수정',
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
                              Navigator.pushNamed(context, '/settings');
                            },
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ⭐ 실제 평점 카드 (API 연동)
                      _buildRatingSection(),

                      const SizedBox(height: 16),

                      // 태그 카드 (표시 전용)
                      _SectionCard(
                        title: '태그',
                        trailing: Text(
                          '${tags.length}/5',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        child: tags.isEmpty
                            ? const Text(
                          '설정된 태그가 없습니다.\n"내 정보 수정" 에서 관심 태그를 선택해 주세요.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        )
                            : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in tags)
                              _TagChip(
                                label: _displayTagLabel(t),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 지역 카드 (표시 전용)
                      _SectionCard(
                        title: '지역',
                        trailing: Text(
                          '${regions.length}/5',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        child: regions.isEmpty
                            ? const Text(
                          '설정된 지역이 없습니다.\n"내 정보 수정" 에서 활동 지역을 선택해 주세요.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        )
                            : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final r in regions)
                              _TagChip(
                                // 지역은 라벨 그대로 저장/표시
                                label: r,
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

  // ⭐ 평점 섹션 위젯 (API 값 기반)
  Widget _buildRatingSection() {
    if (_ratingLoading) {
      return const _SectionCard(
        title: '평점',
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_ratingError != null) {
      return _SectionCard(
        title: '평점',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _ratingError!,
            style: const TextStyle(fontSize: 13, color: Colors.redAccent),
          ),
        ),
      );
    }

    // 총 개수 0이면 "아직 받은 평점이 없습니다" 표시
    if (_ratingTotalCount == 0) {
      return const _SectionCard(
        title: '평점',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '아직 받은 평점이 없습니다.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      );
    }

    double ratio(int count) {
      if (_ratingTotalCount == 0) return 0.0;
      return count / _ratingTotalCount;
    }

    return _SectionCard(
      title: '평점',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _ratingAverage.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '/ 5',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($_ratingTotalCount)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RatingBarRow(
            star: 5,
            count: _count5,
            ratio: ratio(_count5),
          ),
          _RatingBarRow(
            star: 4,
            count: _count4,
            ratio: ratio(_count4),
          ),
          _RatingBarRow(
            star: 3,
            count: _count3,
            ratio: ratio(_count3),
          ),
          _RatingBarRow(
            star: 2,
            count: _count2,
            ratio: ratio(_count2),
          ),
          _RatingBarRow(
            star: 1,
            count: _count1,
            ratio: ratio(_count1),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

// 태그/지역 칩 (표시 전용)
class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({
    required this.label,
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
    );
  }
}

// 평점 바
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
      padding: const EdgeInsets.symmetric(vertical: 3),
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
