import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _livingInCtrl = TextEditingController();
  final _introCtrl = TextEditingController();

  // ===================== 공통 컬러 =====================
  static const cream = Color(0xFFFFF7F1);
  static const orange = Color(0xFFF29D52);
  static const brown = Color(0xFF734124);
  static const chipBg = Color(0xFFF5E4D6);

  // ===================== 태그 / 언어 옵션 =====================

  /// 마이페이지에서 사용할 고정 태그 (최대 5개 선택)
  /// 코드는 서버/DB에서 사용하기 좋게 영문으로, 라벨은 한글로.
  static const Map<String, String> _tagOptions = {
    'LIFE': '생활',
    'STUDY': '학업',
    'REGION': '지역',
    'JOB': '취업',
    'SAFETY': '안전',
  };

  /// 구사 언어 옵션
  /// code -> label
  /// (향후 백엔드에서도 같은 코드값을 기준으로 Enum/상수 등으로 맞춰주면 좋음)
  static const Map<String, String> _languageOptions = {
    'ko': '한국어',
    'en': 'English',
    'ja': '日本語',
    'zh': '中文',
    'ms': 'Bahasa Melayu',
    'fr': 'Français',
    'de': 'Deutsch',
  };

  /// 국가별 "출신 지역" 리스트 (라벨 그대로 저장)
  /// ➜ 여기서는 라벨(String)만 다루고, 서버에도 라벨 그대로 보냄.
  static final Map<String, List<String>> _regionsByCountry = {
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

  // ===================== 상태값 =====================

  String? _gender; // 'MALE' | 'FEMALE' | 'OTHER' | null
  DateTime? _birthdate;

  /// 태그는 코드(LIFE/…),
  /// 구사 언어는 코드(ko/en/…) ,
  /// 지역은 라벨 그대로 저장 (예: 'Kuala Lumpur', '서울')
  Set<String> _tags = {};
  Set<String> _languages = {};
  Set<String> _regions = {};

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthState>();
      if (!auth.isLoggedIn) {
        if (mounted) Navigator.pushReplacementNamed(context, '/');
        return;
      }

      // 서버 최신값 가져오기
      await auth.fetchProfileBasic();

      final p = auth.profile ?? {};
      setState(() {
        // gender
        final g = (p['gender'] as String? ?? '').trim();
        _gender = g.isEmpty ? null : g;

        // birthdate (yyyy-MM-dd)
        final bd = (p['birthdate'] as String?);
        if (bd != null && bd.trim().isNotEmpty) {
          try {
            _birthdate = DateTime.parse(bd);
          } catch (_) {}
        }

        // livingIn / introduction
        _livingInCtrl.text = (p['livingIn'] as String?)?.trim() ?? '';
        _introCtrl.text = (p['introduction'] as String?)?.trim() ?? '';

        // 태그: ["LIFE","STUDY"] / "LIFE,STUDY" / ["생활","학업"] 모두 처리
        final rawTags = p['tags'];
        _tags = _parseCodes(rawTags, _tagOptions, maxCount: 5);

        // 구사 언어: ["ko","en"] / "ko,en" / ["한국어","English"] 모두 처리
        final rawLanguages = p['languages'];
        _languages = _parseCodes(rawLanguages, _languageOptions, maxCount: 5);

        // 지역: ["Kuala Lumpur","서울"] / "Kuala Lumpur,서울" 모두 처리
        final rawRegions = p['regions'];
        _regions = _parseRegions(rawRegions, maxCount: 5);
      });
    });
  }

  @override
  void dispose() {
    _livingInCtrl.dispose();
    _introCtrl.dispose();
    super.dispose();
  }

  // ===================== 매핑 유틸 =====================

  /// 태그/언어용: 라벨 또는 코드를 받아서 "코드"로 변환
  String? _toCode(String value, Map<String, String> options) {
    if (value.isEmpty) return null;

    // 코드 그대로
    if (options.containsKey(value)) return value;

    // 라벨(한글/영문)로 들어온 경우 역탐색
    final found = options.entries.firstWhere(
          (e) => e.value == value,
      orElse: () => const MapEntry('', ''),
    );
    return found.key.isEmpty ? null : found.key;
  }

  /// 서버에서 온 값(raw)을 Set<code>로 변환 (태그/언어용 공통)
  Set<String> _parseCodes(
      dynamic raw,
      Map<String, String> options, {
        int maxCount = 999,
      }) {
    final result = <String>{};
    if (raw == null) return result;

    Iterable<String> parts;
    if (raw is List) {
      parts = raw.map((e) => e.toString());
    } else if (raw is String) {
      parts = raw.split(',');
    } else {
      return result;
    }

    for (final part in parts) {
      final code = _toCode(part.trim(), options);
      if (code != null) {
        result.add(code);
        if (result.length >= maxCount) break;
      }
    }
    return result;
  }

  /// 서버에서 온 지역(raw)을 Set<label>로 변환
  Set<String> _parseRegions(
      dynamic raw, {
        int maxCount = 999,
      }) {
    final result = <String>{};
    if (raw == null) return result;

    Iterable<String> parts;
    if (raw is List) {
      parts = raw.map((e) => e.toString());
    } else if (raw is String) {
      parts = raw.split(',');
    } else {
      return result;
    }

    for (final part in parts) {
      final v = part.trim();
      if (v.isEmpty) continue;
      result.add(v);
      if (result.length >= maxCount) break;
    }
    return result;
  }

  // ===================== UI 유틸 =====================

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final initial = _birthdate ?? DateTime(now.year - 20, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthdate = picked);
    }
  }

  Future<void> _openRegionPicker() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RegionPickerBottomSheet(
        initialSelected: _regions.toList(),
        regionsByCountry: _regionsByCountry,
        maxSelection: 5,
      ),
    );

    if (result != null) {
      setState(() {
        _regions = result.toSet();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // 서버에 보낼 때
    // - 태그: 코드 리스트
    // - 구사 언어: 코드 리스트
    // - 지역: 라벨 문자열 리스트
    final tagCodes = _tags.toList();
    final languageCodes = _languages.toList();
    final regionLabels = _regions.toList();

    final ok = await context.read<AuthState>().updateProfileBasic(
      gender: _gender,
      birthdate: _birthdate,
      livingIn: _livingInCtrl.text.trim(),
      introduction: _introCtrl.text.trim(),
      tags: tagCodes,
      languages: languageCodes, // ✅ 새로 추가 (AuthState에도 반영 필요)
      regions: regionLabels,
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내 정보가 저장되었습니다.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 실패. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: brown, size: 20),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: brown,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  /// 멀티 선택 칩 영역 (태그/언어용)
  Widget _buildMultiChipGroup({
    required Map<String, String> options,
    required Set<String> selectedValues,
    required void Function(String code) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final code = e.key;
        final label = e.value;
        final selected = selectedValues.contains(code);

        return ChoiceChip(
          label: Text(label),
          selected: selected,
          backgroundColor: chipBg,
          selectedColor: orange.withOpacity(0.85),
          labelStyle: TextStyle(
            color: selected ? Colors.white : brown,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (_) => onToggle(code),
        );
      }).toList(),
    );
  }

  // ===================== 빌드 =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: brown),
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
          '내 정보 수정',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ========= 섹션: 기본 정보 =========
                        _buildSectionTitle(Icons.person, '기본 정보'),
                        const SizedBox(height: 12),

                        // 성별
                        DropdownButtonFormField<String>(
                          value: _gender,
                          items: const [
                            DropdownMenuItem(
                              value: 'MALE',
                              child: Text('남성'),
                            ),
                            DropdownMenuItem(
                              value: 'FEMALE',
                              child: Text('여성'),
                            ),
                            DropdownMenuItem(
                              value: 'OTHER',
                              child: Text('기타/선택안함'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: '성별',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _gender = v),
                        ),
                        const SizedBox(height: 12),

                        // 생년월일
                        Row(
                          children: [
                            Expanded(
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: '생년월일',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                child: Text(
                                  _birthdate == null
                                      ? '미설정'
                                      : '${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _pickBirthdate,
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: const Text('선택'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: brown,
                                side: const BorderSide(color: brown),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ========= 섹션: 태그 & 언어 & 지역 =========
                        _buildSectionTitle(Icons.sell, '관심 태그 & 구사 언어 & 활동 지역'),
                        const SizedBox(height: 10),

                        const Text(
                          '마이페이지에 표시될 태그, 구사 언어, 지역을 선택해 주세요.\n'
                              '각 항목은 최대 5개까지 선택할 수 있어요.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 구사 언어
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '구사 언어',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_languages.length}/5',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildMultiChipGroup(
                          options: _languageOptions,
                          selectedValues: _languages,
                          onToggle: (code) {
                            setState(() {
                              if (_languages.contains(code)) {
                                _languages.remove(code);
                              } else {
                                if (_languages.length >= 5) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                      Text('구사 언어는 최대 5개까지 선택할 수 있어요.'),
                                    ),
                                  );
                                  return;
                                }
                                _languages.add(code);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // 관심 태그
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '관심 태그',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_tags.length}/5',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildMultiChipGroup(
                          options: _tagOptions,
                          selectedValues: _tags,
                          onToggle: (code) {
                            setState(() {
                              if (_tags.contains(code)) {
                                _tags.remove(code);
                              } else {
                                if (_tags.length >= 5) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                      Text('태그는 최대 5개까지 선택할 수 있어요.'),
                                    ),
                                  );
                                  return;
                                }
                                _tags.add(code);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // 활동 지역 (요약 + 바텀시트 선택)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '활동 지역',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_regions.length}/5',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _openRegionPicker,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _regions.isEmpty
                                ? Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  '지역을 선택해 주세요',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: Colors.black45,
                                ),
                              ],
                            )
                                : Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _regions
                                        .map(
                                          (r) => Chip(
                                        label: Text(
                                          r,
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor:
                                        Colors.white,
                                        materialTapTargetSize:
                                        MaterialTapTargetSize
                                            .shrinkWrap,
                                        padding: const EdgeInsets
                                            .symmetric(
                                          horizontal: 8,
                                          vertical: 0,
                                        ),
                                      ),
                                    )
                                        .toList(),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ========= 섹션: 거주지 & 자기소개 =========
                        _buildSectionTitle(Icons.home, '거주지 & 자기소개'),
                        const SizedBox(height: 12),

                        // 거주지
                        TextFormField(
                          controller: _livingInCtrl,
                          decoration: const InputDecoration(
                            labelText: '현재 거주지',
                            hintText: '예: 인천 미추홀구 학익동',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 소개
                        TextFormField(
                          controller: _introCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: '자기소개',
                            hintText: '간단하게 나를 소개해 주세요 :)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 저장 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _loading ? null : _save,
                            child: _loading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                                : const Text(
                              '저장',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 국가별로 정리된 지역 선택 바텀시트
class RegionPickerBottomSheet extends StatefulWidget {
  final List<String> initialSelected;
  final Map<String, List<String>> regionsByCountry;
  final int maxSelection;

  const RegionPickerBottomSheet({
    Key? key,
    required this.initialSelected,
    required this.regionsByCountry,
    this.maxSelection = 5,
  }) : super(key: key);

  @override
  State<RegionPickerBottomSheet> createState() =>
      _RegionPickerBottomSheetState();
}

class _RegionPickerBottomSheetState extends State<RegionPickerBottomSheet> {
  late String _selectedCountry;
  late List<String> _selectedRegions;

  @override
  void initState() {
    super.initState();
    _selectedRegions = [...widget.initialSelected];
    _selectedCountry = widget.regionsByCountry.keys.first;
  }

  void _toggleRegion(String region) {
    setState(() {
      if (_selectedRegions.contains(region)) {
        _selectedRegions.remove(region);
      } else {
        if (_selectedRegions.length >= widget.maxSelection) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text('지역은 최대 ${widget.maxSelection}개까지 선택할 수 있어요.'),
            ),
          );
          return;
        }
        _selectedRegions.add(region);
      }
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
                          Navigator.of(context).pop(_selectedRegions);
                        },
                        child: const Text('완료'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 선택된 요약
                if (_selectedRegions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedRegions
                          .map(
                            (r) => Chip(
                          label: Text(
                            r,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onDeleted: () => _toggleRegion(r),
                        ),
                      )
                          .toList(),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '선택된 지역이 없습니다.',
                      style: TextStyle(color: Colors.grey),
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

                // 국가별 지역 칩 목록
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: regions.map((r) {
                        final selected = _selectedRegions.contains(r);
                        return FilterChip(
                          label: Text(
                            r,
                            style: const TextStyle(fontSize: 13),
                          ),
                          selected: selected,
                          onSelected: (_) => _toggleRegion(r),
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
