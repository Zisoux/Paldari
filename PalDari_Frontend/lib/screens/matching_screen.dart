import 'package:flutter/material.dart';
import '../services/api.dart';
import 'chat_room_screen.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final ApiService _api = ApiService();

  // UI 상태
  String? selectedNationality; // BUDDY의 국적
  String? selectedCategory; // 카테고리
  bool showAdvanced = false; // 상세 조건 영역 토글
  bool _loading = false; // 전체 매칭 진행 중 로딩

  // 상세 조건 상태 (부모에서 관리)
  String? _region;
  String? _gender; // '무관' / '남성' / '여성'
  RangeValues _ageRange = const RangeValues(20, 30);

  // 목업 데이터 (국적/카테고리)
  final nationalities = const ['한국', '일본', '말레이시아', '미국', '기타'];
  final categories = const ['생활', '학업', '지역', '안전', '취업'];

  // ---------------- 매칭 공통 로직 ----------------

  /// 매칭 시작 (조건 기반 / 랜덤 선택)
  Future<void> _startMatching({required bool random}) async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      Map<String, dynamic>? pal;

      if (random) {
        // 조건 없이 랜덤 Pal
        pal = await _api.findRandomMatch();
      } else {
        // 조건 기반 "가장 우선순위 높은 1명"
        pal = await _api.findBestMatch(
          nationality: selectedNationality,
          category: selectedCategory,
          region: _region,
          gender: _gender,
          minAge: _ageRange.start.round(),
          maxAge: _ageRange.end.round(),
        );
      }

      if (!mounted) return;

      if (pal == null) {
        // 매칭 가능한 유저 없음
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text(random ? '매칭 가능한 Pal이 없어요. 😢' : '조건에 맞는 Pal을 찾지 못했어요.'),
          ),
        );
        setState(() => _loading = false);
        return;
      }

      // 매칭된 Pal 확인/취소 모달 띄우기
      await _showMatchDialog(pal);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('매칭 중 오류가 발생했어요: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// "매칭되었어요!" 모달
  Future<void> _showMatchDialog(Map<String, dynamic> pal) async {
    final nickname = (pal['nickname'] ??
        pal['username'] ??
        pal['name'] ??
        '알 수 없는 Pal')
        .toString();
    final country = (pal['country'] ?? '').toString();
    final lang = (pal['language'] ?? '').toString();
    final intro = (pal['introduction'] ?? '').toString();

    final targetUserId = pal['id'] ?? pal['userId'];
    if (targetUserId == null) {
      // 백엔드 응답 형식이 바뀌어서 id가 없으면 그냥 안내만
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('매칭 정보에 사용자 ID가 없어요. 백엔드 응답을 확인해주세요.')),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '매칭된 Pal을 발견했어요! 🎉',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('닉네임: $nickname'),
              if (country.isNotEmpty) Text('국가: $country'),
              if (lang.isNotEmpty) Text('언어: $lang'),
              if (intro.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  '소개',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  intro,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                '이 Pal과 채팅을 시작해 볼까요?',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // 닫기
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // 모달 닫고 채팅 생성 진행
                await _createChatAndOpen(targetUserId as int, nickname);
              },
              child: const Text('채팅 시작'),
            ),
          ],
        );
      },
    );
  }

  /// 채팅방 생성 후 바로 ChatRoomScreen으로 이동
  Future<void> _createChatAndOpen(int targetUserId, String fallbackName) async {
    setState(() => _loading = true);
    try {
      final room =
      await _api.createChatForMatching(targetUserId: targetUserId);

      if (!mounted) return;

      final roomIdDynamic = room['roomId'] ?? room['id'];
      if (roomIdDynamic == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('채팅방 ID를 찾을 수 없어요. 응답 형식을 확인해주세요.')),
        );
        return;
      }

      final roomId = roomIdDynamic is int
          ? roomIdDynamic
          : int.tryParse(roomIdDynamic.toString()) ?? 0;

      final roomName = (room['name'] ?? fallbackName).toString();

      // 채팅방으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: roomId,
            roomName: roomName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방 생성 중 오류가 발생했어요: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF7F1);
    const brown = Color(0xFF734124);
    const orange = Color(0xFFF39D52);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF734124)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        centerTitle: true,
        title: const Text(
          'Pal 매칭',
          style: TextStyle(
            color: Color(0xFF141414),
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // 1) BUDDY의 국적은?
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'BUDDY의 국적은?',
                    style: TextStyle(
                      color: brown,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final n in nationalities)
                      ChoiceChip(
                        label: Text(n),
                        selected: selectedNationality == n,
                        selectedColor: orange.withOpacity(0.6),
                        onSelected: (_) =>
                            setState(() => selectedNationality = n),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2) 카테고리 선택
                const Center(
                  child: Text(
                    '카테고리 선택',
                    style: TextStyle(
                      color: brown,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final c in categories)
                      ChoiceChip(
                        label: Text(c),
                        selected: selectedCategory == c,
                        selectedColor: orange.withOpacity(0.6),
                        onSelected: (_) =>
                            setState(() => selectedCategory = c),
                      ),
                  ],
                ),

                const SizedBox(height: 28),

                // 3) 상세 조건 카드 (토글)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Image.network(
                    'https://placehold.co/24x21/png',
                    width: 24,
                    height: 21,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.tune, color: brown),
                  ),
                  title: const Text(
                    '상세 조건 설정(선택)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: brown,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(
                    showAdvanced ? Icons.expand_less : Icons.expand_more,
                    color: brown,
                  ),
                  onTap: () => setState(() => showAdvanced = !showAdvanced),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFF29D52)),
                  ),
                ),

                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _AdvancedFilters(
                      region: _region,
                      gender: _gender,
                      ageRange: _ageRange,
                      onRegionChanged: (v) =>
                          setState(() => _region = v),
                      onGenderChanged: (v) =>
                          setState(() => _gender = v),
                      onAgeRangeChanged: (v) =>
                          setState(() => _ageRange = v),
                    ),
                  ),
                  crossFadeState: showAdvanced
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),

                const SizedBox(height: 28),

                // 4) 매칭 시작 버튼
                SizedBox(
                  height: 51,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side:
                        BorderSide(color: Colors.black.withOpacity(0.5)),
                      ),
                    ),
                    onPressed:
                    _loading ? null : () => _startMatching(random: false),
                    child: const Text(
                      '매칭 시작',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // 구분선 + 또는
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Expanded(
                        child:
                        Divider(color: Color(0xFF595959), height: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('또는',
                          style: TextStyle(color: Color(0xFF595959))),
                    ),
                    Expanded(
                        child:
                        Divider(color: Color(0xFF595959), height: 1)),
                  ],
                ),
                const SizedBox(height: 16),

                // 5) 조건 없이 빠른 대화 시작
                SizedBox(
                  height: 51,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF595959),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side:
                        BorderSide(color: Colors.black.withOpacity(0.5)),
                      ),
                    ),
                    onPressed:
                    _loading ? null : () => _startMatching(random: true),
                    child: const Text(
                      '조건 없이 빠른 대화 시작',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),

            // 전체 로딩 오버레이
            if (_loading)
              Container(
                color: Colors.black.withOpacity(0.1),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

/// 상세 조건(선택) - 부모에서 상태를 관리하고, 여기서는 UI + 콜백만 담당
class _AdvancedFilters extends StatelessWidget {
  final String? region;
  final String? gender;
  final RangeValues ageRange;
  final ValueChanged<String?> onRegionChanged;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<RangeValues> onAgeRangeChanged;

  const _AdvancedFilters({
    super.key,
    required this.region,
    required this.gender,
    required this.ageRange,
    required this.onRegionChanged,
    required this.onGenderChanged,
    required this.onAgeRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 지역
        const Text('지역', style: labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: region,
          items: const [
            DropdownMenuItem(value: '서울', child: Text('서울')),
            DropdownMenuItem(value: '인천', child: Text('인천')),
            DropdownMenuItem(value: '쿠알라룸푸르', child: Text('쿠알라룸푸르')),
          ],
          onChanged: onRegionChanged,
          decoration: _fieldDecoration(),
        ),
        const SizedBox(height: 16),

        // 성별
        const Text('성별', style: labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: gender,
          items: const [
            DropdownMenuItem(value: '무관', child: Text('무관')),
            DropdownMenuItem(value: '남성', child: Text('남성')),
            DropdownMenuItem(value: '여성', child: Text('여성')),
          ],
          onChanged: onGenderChanged,
          decoration: _fieldDecoration(),
        ),
        const SizedBox(height: 16),

        // 나이 범위
        const Text('나이 범위', style: labelStyle),
        const SizedBox(height: 4),
        RangeSlider(
          min: 15,
          max: 60,
          divisions: 45,
          values: ageRange,
          labels: RangeLabels(
            '${ageRange.start.round()}',
            '${ageRange.end.round()}',
          ),
          onChanged: onAgeRangeChanged,
        ),
      ],
    );
  }

  static InputDecoration _fieldDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF29D52), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF29D52), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF29D52), width: 2),
      ),
    );
  }
}
