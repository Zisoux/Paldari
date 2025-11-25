import 'package:flutter/material.dart';
import '../services/api.dart';
import 'chat_room_screen.dart';

/// 매칭 화면에서 사용할 국가별 활동 지역 리스트
/// EditProfileScreen._regionsByCountry 와 동일한 라벨을 사용해서
/// DB / 마이페이지와 값이 정확히 맞도록 함.
const Map<String, List<String>> _regionsByCountryForMatching = {
  // 🇲🇾 Malaysia
  '말레이시아': [
    'Kuala Lumpur',
    'Selangor (Shah Alam, Petaling Jaya)',
    'Penang (George Town)',
    'Johor (Johor Bahru)',
    'Sabah (Kota Kinabalu)',
    'Sarawak (Kuching)',
    'Melaka',
    'Negeri Sembilan (Seremban)',
    'Perak (Ipoh)',
    'Kedah (Alor Setar)',
    'Terengganu (Kuala Terengganu)',
    'Pahang (Kuantan)',
    'Perlis (Kangar)',
    'Putrajaya',
    'Labuan',
  ],

  // 🇰🇷 South Korea
  '한국': [
    '서울',
    '부산',
    '대구',
    '인천',
    '광주',
    '대전',
    '울산',
    '세종',
    '경기도',
    '강원도',
    '충청북도',
    '충청남도',
    '전라북도',
    '전라남도',
    '경상북도',
    '경상남도',
    '제주도',
  ],

  // 🇯🇵 Japan
  '일본': [
    'Tokyo',
    'Osaka',
    'Kyoto',
    'Kanagawa (Yokohama)',
    'Saitama',
    'Chiba',
    'Hokkaido (Sapporo)',
    'Aichi (Nagoya)',
    'Hyogo (Kobe)',
    'Fukuoka',
    'Hiroshima',
    'Okinawa',
    'Shizuoka',
    'Miyagi (Sendai)',
    'Nara',
    'Okayama',
    'Kumamoto',
    'Tochigi',
    'Kagoshima',
    'Niigata',
  ],

  // 🇺🇸 United States
  '미국': [
    'California',
    'New York',
    'Texas',
    'Florida',
    'Washington',
    'Illinois',
    'New Jersey',
    'Pennsylvania',
    'Massachusetts',
    'Georgia',
    'Virginia',
    'Colorado',
    'Arizona',
    'Nevada',
    'Michigan',
    'Ohio',
    'Oregon',
    'Tennessee',
    'North Carolina',
    'Maryland',
    'Hawaii',
    'Minnesota',
    'Wisconsin',
    'Indiana',
    'Utah',
    'District of Columbia',
  ],

  // 🇨🇦 Canada
  '캐나다': [
    'Ontario',
    'Quebec',
    'British Columbia',
    'Alberta',
    'Manitoba',
    'Saskatchewan',
    'Nova Scotia',
    'New Brunswick',
    'Newfoundland & Labrador',
    'Prince Edward Island',
    'Yukon',
    'Northwest Territories',
    'Nunavut',
  ],

  // 🇦🇺 Australia
  '호주': [
    'New South Wales (Sydney)',
    'Victoria (Melbourne)',
    'Queensland (Brisbane / Gold Coast)',
    'Western Australia (Perth)',
    'South Australia (Adelaide)',
    'Tasmania (Hobart)',
    'Australian Capital Territory (Canberra)',
    'Northern Territory (Darwin)',
  ],

  // 🇬🇧 United Kingdom
  '영국': [
    'London',
    'Manchester',
    'Liverpool',
    'Birmingham',
    'Leeds',
    'Sheffield',
    'Newcastle',
    'Bristol',
    'Edinburgh',
    'Glasgow',
    'Cardiff',
    'Belfast',
  ],

  // 🇩🇪 Germany
  '독일': [
    'Bavaria (Munich)',
    'Berlin',
    'Hamburg',
    'Baden-Württemberg (Stuttgart)',
    'North Rhine–Westphalia (Cologne, Düsseldorf)',
    'Hesse (Frankfurt)',
    'Saxony (Dresden, Leipzig)',
    'Lower Saxony (Hannover)',
    'Rhineland-Palatinate (Mainz)',
    'Schleswig-Holstein (Kiel)',
    'Brandenburg (Potsdam)',
    'Saxony-Anhalt',
    'Thuringia (Erfurt)',
    'Bremen',
    'Saarland',
    'Mecklenburg-Vorpommern',
  ],

  // 🇫🇷 France
  '프랑스': [
    'Île-de-France (Paris)',
    'Provence-Alpes-Côte d’Azur (Nice / Marseille)',
    'Auvergne-Rhône-Alpes (Lyon)',
    'Occitanie (Toulouse / Montpellier)',
    'Nouvelle-Aquitaine (Bordeaux)',
    'Grand Est (Strasbourg)',
    'Hauts-de-France (Lille)',
    'Normandy (Rouen)',
    'Pays de la Loire (Nantes)',
    'Brittany (Rennes)',
    'Centre-Val-de-Loire (Orléans)',
    'Burgundy-Franche-Comté (Dijon)',
    'Corsica (Ajaccio)',
  ],
};

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final ApiService _api = ApiService();

  // UI 상태
  String? selectedNationality; // Pal 국적
  String? selectedCategory; // 카테고리
  bool _loading = false; // 전체 매칭 진행 중 로딩

  // 상세 조건 상태
  String? _region; // 활동 지역 (문자열로 입력)
  String? _language; // 사용 언어 (드롭다운)
  String? _gender; // '무관' / '남성' / '여성'

  bool _showAdvanced = false; // ⭐ 상세 조건 펼침 여부

  // 국적 리스트 (Pal 국적 선택용)
  final nationalities = const [
    '한국',
    '말레이시아',
    '일본',
    '미국',
    '캐나다',
    '호주',
    '영국',
    '독일',
    '프랑스',
  ];

  // 카테고리 리스트 (그대로)
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
        // 🔸 region = 활동 지역, language = 사용 언어
        pal = await _api.findBestMatch(
          nationality: selectedNationality,
          category: selectedCategory,
          region: _region,
          language: _language,
          gender: _gender,
        );
      }

      if (!mounted) return;

      if (pal == null) {
        // 매칭 가능한 유저 없음
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              random
                  ? '매칭 가능한 Pal이 없어요. 😢'
                  : '조건에 맞는 Pal을 찾지 못했어요.',
            ),
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
    final nickname =
    (pal['nickname'] ?? pal['username'] ?? pal['name'] ?? '알 수 없는 Pal')
        .toString();
    final country = (pal['country'] ?? '').toString();
    final lang = (pal['language'] ?? '').toString();
    final intro = (pal['introduction'] ?? '').toString();

    final targetUserId = pal['id'];
    if (targetUserId == null) {
      // 백엔드 응답 형식이 바뀌어서 id가 없으면 그냥 안내만
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('매칭 정보에 사용자 ID가 없어요. 백엔드 응답을 확인해주세요.')),
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
      final room = await _api.createChatForMatching(targetUserId: targetUserId);

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
            buddyUserId: room['buddyUserId'],   // ⭐ 여기 추가 (정답)
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
                // 1) Pal 국적 선택
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Pal 국적 선택',
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

                // 3) 상세 조건 설정 (버튼으로 펼치기/접기)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '상세 조건 설정 (선택)',
                      style: TextStyle(
                        color: brown,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAdvanced = !_showAdvanced;
                        });
                      },
                      icon: Icon(
                        _showAdvanced ? Icons.expand_less : Icons.expand_more,
                        color: brown,
                      ),
                      label: Text(
                        _showAdvanced ? '접기' : '열기',
                        style: const TextStyle(color: brown),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_showAdvanced)
                  _AdvancedFilters(
                    region: _region,
                    language: _language,
                    gender: _gender,
                    onRegionChanged: (v) => setState(() => _region = v),
                    onLanguageChanged: (v) => setState(() => _language = v),
                    onGenderChanged: (v) => setState(() => _gender = v),
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
                      child: Divider(color: Color(0xFF595959), height: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '또는',
                        style: TextStyle(color: Color(0xFF595959)),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Color(0xFF595959), height: 1),
                    ),
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

/// 상세 조건(선택) - 활동 지역 + 사용 언어 + 성별
class _AdvancedFilters extends StatelessWidget {
  final String? region;
  final String? language;
  final String? gender;
  final ValueChanged<String?> onRegionChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<String?> onGenderChanged;

  const _AdvancedFilters({
    super.key,
    required this.region,
    required this.language,
    required this.gender,
    required this.onRegionChanged,
    required this.onLanguageChanged,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontWeight: FontWeight.w600);
    // region이 null 또는 빈 문자열이면 "전체"로 간주 (선택 안 함)
    final selectedRegion = (region ?? '').isNotEmpty ? region : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 활동 지역 (바텀시트, EditProfile과 유사 UI)
        const Text('활동 지역', style: labelStyle),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => RegionPickerBottomSheetForMatching(
                initialSelected: selectedRegion,
                regionsByCountry: _regionsByCountryForMatching,
              ),
            );

            // null 이 아니면 선택값 반영
            if (selected != null) {
              onRegionChanged(selected);
            }
          },
          child: InputDecorator(
            decoration: _fieldDecoration().copyWith(
              hintText: '활동 지역 선택 (선택사항)',
            ),
            child: Text(
              selectedRegion ?? '지역을 선택해 주세요',
              style: TextStyle(
                color: selectedRegion == null ? Colors.black54 : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 사용 언어
        const Text('사용 언어', style: labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: language,
          items: const [
            DropdownMenuItem(value: '한국어', child: Text('한국어')),
            DropdownMenuItem(value: 'English (US)', child: Text('English (US)')),
            DropdownMenuItem(
              value: 'Bahasa Melayu',
              child: Text('Bahasa Melayu'),
            ),
            DropdownMenuItem(value: '日本語', child: Text('日本語')),
            DropdownMenuItem(value: 'Deutsch', child: Text('Deutsch')),
            DropdownMenuItem(value: 'Français', child: Text('Français')),
            DropdownMenuItem(
              value: 'English (UK)',
              child: Text('English (UK)'),
            ),
            DropdownMenuItem(
              value: 'English (CA)',
              child: Text('English (CA)'),
            ),
            DropdownMenuItem(
              value: 'English (AU)',
              child: Text('English (AU)'),
            ),
          ],
          onChanged: onLanguageChanged,
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

/// 매칭용 지역 선택 바텀시트 (단일 선택)
class RegionPickerBottomSheetForMatching extends StatefulWidget {
  final String? initialSelected;
  final Map<String, List<String>> regionsByCountry;

  const RegionPickerBottomSheetForMatching({
    Key? key,
    required this.initialSelected,
    required this.regionsByCountry,
  }) : super(key: key);

  @override
  State<RegionPickerBottomSheetForMatching> createState() =>
      _RegionPickerBottomSheetForMatchingState();
}

class _RegionPickerBottomSheetForMatchingState
    extends State<RegionPickerBottomSheetForMatching> {
  late String _selectedCountry;
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.regionsByCountry.keys.first;
    _selectedRegion = widget.initialSelected;
  }

  void _selectRegion(String region) {
    setState(() {
      _selectedRegion = region;
    });
  }

  @override
  Widget build(BuildContext context) {
    final countryList = widget.regionsByCountry.keys.toList();
    final regions = widget.regionsByCountry[_selectedCountry] ?? [];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 타이틀 + 완료 버튼
                Row(
                  children: [
                    const Expanded(
                      child: Center(
                        child: Text(
                          '활동 지역 선택',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(_selectedRegion);
                        },
                        child: const Text('완료'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 선택된 요약
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _selectedRegion == null
                        ? '선택된 지역이 없습니다.'
                        : '선택된 지역: $_selectedRegion',
                    style: TextStyle(
                      color:
                      _selectedRegion == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),

                const Divider(),

                // 국가 선택 칩
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: countryList.map((c) {
                      final selected = c == _selectedCountry;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCountry = c;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // 국가별 지역 칩 목록 (단일 선택)
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: regions.map((r) {
                        final selected = _selectedRegion == r;
                        return FilterChip(
                          label: Text(
                            r,
                            style: const TextStyle(fontSize: 13),
                          ),
                          selected: selected,
                          onSelected: (_) => _selectRegion(r),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
