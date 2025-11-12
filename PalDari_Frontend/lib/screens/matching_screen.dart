import 'package:flutter/material.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  // UI 상태 (임시 목업 상태값들)
  String? selectedNationality; // BUDDY의 국적
  String? selectedCategory;    // 카테고리
  bool showAdvanced = false;   // 상세 조건 영역 토글

  // 목업 데이터
  final nationalities = const ['한국', '일본', '말레이시아', '미국', '기타'];
  final categories    = const ['생활', '학업', '지역', '안전', '취업'];

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
              Navigator.pop(context);            // 스택에 이전 화면 있으면 그대로 뒤로
            } else {
              Navigator.pushReplacementNamed(     // 없으면 홈으로 안전 복귀
                context,
                '/home',
              );
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
        child: ListView(
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

            // 간단한 선택 칩
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
                    onSelected: (_) => setState(() => selectedNationality = n),
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
                    onSelected: (_) => setState(() => selectedCategory = c),
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
                errorBuilder: (_, __, ___) => const Icon(Icons.tune, color: brown),
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
                child: _AdvancedFilters(),
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
                    side: BorderSide(color: Colors.black.withOpacity(0.5)),
                  ),
                ),
                onPressed: () {
                  // TODO: 매칭 API 호출 (다음 단계에서 연결)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('매칭 시작 (임시 버튼)')),
                  );
                },
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
                Expanded(child: Divider(color: Color(0xFF595959), height: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('또는', style: TextStyle(color: Color(0xFF595959))),
                ),
                Expanded(child: Divider(color: Color(0xFF595959), height: 1)),
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
                    side: BorderSide(color: Colors.black.withOpacity(0.5)),
                  ),
                ),
                onPressed: () {
                  // TODO: 랜덤/빠른 매칭 로직 (다음 단계)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('빠른 대화 시작 (임시 버튼)')),
                  );
                },
                child: const Text(
                  '조건 없이 빠른 대화 시작',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 상세 조건(선택) — 지금은 목업 필드만 배치. 다음 단계에서 실제 필터 옵션 붙임.
class _AdvancedFilters extends StatefulWidget {
  const _AdvancedFilters();

  @override
  State<_AdvancedFilters> createState() => _AdvancedFiltersState();
}

class _AdvancedFiltersState extends State<_AdvancedFilters> {
  // 임시 필터 상태 (예시)
  String? region;
  String? gender;
  RangeValues? ageRange = const RangeValues(20, 30);

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
          onChanged: (v) => setState(() => region = v),
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
          onChanged: (v) => setState(() => gender = v),
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
          values: ageRange ?? const RangeValues(20, 30),
          labels: RangeLabels(
            '${(ageRange ?? const RangeValues(20, 30)).start.round()}',
            '${(ageRange ?? const RangeValues(20, 30)).end.round()}',
          ),
          onChanged: (v) => setState(() => ageRange = v),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
