import 'package:flutter/material.dart';
import 'package:paldari/screens/settings_screen.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api.dart';
import '../widgets/pal_bottom_nav.dart';

/// PalDari Home Screen

class PalColors {
  PalColors._();
  static const cream = Color(0xFFFFF7F1);
  static const orange = Color(0xFFF29D52); // borders / accents
  static const orangeSolid = Color(0xFFF39D52); // avatar bg
  static const brown = Color(0xFF734124); // brand brown
  static const deepBrown = Color(0xFF260101);
  static const tagRed = Color(0xFFF13855);
  static const tagRedBg = Color(0x35FF5161); // translucent red-ish
  static const textSecondary = Color(0xFF9F9FA1);
}

/// 태그 코드 -> 한글 라벨 매핑 (매칭 설정과 동일)
const Map<String, String> kTagCodeToLabel = {
  'LIFE': '생활',
  'STUDY': '학업',
  'REGION': '지역',
  'JOB': '취업',
  'SAFETY': '안전',
};

/// 매칭 설정에서 사용하던 국가 목록과 동일하게 고정
const List<String> kFilterCountries = [
  '말레이시아',
  '한국',
  '일본',
  '미국',
  '캐나다',
  '호주',
  '영국',
  '독일',
  '프랑스',
];

/// 서버에서 온 값이 코드(LIFE)든, 이미 한글 라벨(생활)이든
/// 화면에 표시할 "라벨"로 변환
String tagLabel(String value) {
  if (kTagCodeToLabel.containsKey(value)) {
    // 코드 -> 라벨
    return kTagCodeToLabel[value]!;
  }
  if (kTagCodeToLabel.containsValue(value)) {
    // 이미 라벨(한글 등)인 경우 그대로 사용
    return value;
  }
  // 매핑에 없는 값이면 있는 그대로 표시
  return value;
}

/// =====================
///    Home Screen
/// =====================

class PalHomeScreen extends StatefulWidget {
  const PalHomeScreen({super.key});

  @override
  State<PalHomeScreen> createState() => _PalHomeScreenState();
}

class _PalHomeScreenState extends State<PalHomeScreen> {
  final GlobalKey<_PalListSectionState> _listKey =
  GlobalKey<_PalListSectionState>();

  @override
  Widget build(BuildContext context) {
    // auth는 지금은 안 쓰지만, 나중에 필요할 수도 있어서 남겨둠
    final auth = context.watch<AuthState>();
    final _ = auth.profile; // profile 변경 시 화면 리빌드를 위해 참조만 유지

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _PalTopAppBar(
          onFilterTap: () {
            _listKey.currentState?.openFilterBottomSheetFromOutside();
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: _PalListSection(key: _listKey),
      ),
      bottomNavigationBar: const PalBottomNav(currentIndex: 0),
    );
  }
}

class _PalTopAppBar extends StatelessWidget {
  const _PalTopAppBar({
    required this.onFilterTap,
  });

  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PalColors.cream,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Pal',
                    style: TextStyle(
                      color: PalColors.brown,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  TextSpan(
                    text: '다리',
                    style: TextStyle(
                      color: PalColors.deepBrown,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: 알림 화면 혹은 Snackbar 등
            },
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            tooltip: 'Settings',
          ),
          IconButton(
            onPressed: onFilterTap,
            icon: const Icon(Icons.tune, color: Colors.black87),
            tooltip: '필터',
          ),
        ],
      ),
    );
  }
}

/// =====================
///   Pal 리스트 + 필터
/// =====================

class _PalListSection extends StatefulWidget {
  const _PalListSection({super.key});

  @override
  State<_PalListSection> createState() => _PalListSectionState();
}

class _PalListSectionState extends State<_PalListSection> {
  final ApiService _api = ApiService();

  bool _loading = false;
  List<Pal> _allPals = [];
  List<Pal> _displayPals = [];

  // 필터 상태
  String? _filterCountry;
  String? _filterTag; // 태그 코드 (LIFE/…)

  @override
  void initState() {
    super.initState();
    _loadPals();
  }

  Future<void> _loadPals() async {
    setState(() => _loading = true);
    try {
      final List<Map<String, dynamic>> raw = await _api.fetchHomePals();
      final pals = raw.map((m) => Pal.fromJson(m)).toList();

      setState(() {
        _allPals = pals;
        _displayPals = _buildFilteredList();
      });
    } catch (e) {
      debugPrint('Failed to load home pals: $e');
      setState(() {
        _allPals = [];
        _displayPals = [];
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// 현재 필터 상태에 맞는 리스트를 만들어서 반환
  List<Pal> _buildFilteredList() {
    final list = List<Pal>.from(_allPals);

    int score(Pal p) {
      int s = 0;
      if (_filterCountry != null &&
          _filterCountry!.isNotEmpty &&
          p.country == _filterCountry) {
        s += 2;
      }
      if (_filterTag != null &&
          _filterTag!.isNotEmpty &&
          p.tags.contains(_filterTag)) {
        s += 1;
      }
      return s;
    }

    list.sort((a, b) => score(b).compareTo(score(a)));
    return list;
  }

  /// 외부(AppBar)에서 필터 버튼 눌렀을 때 호출
  void openFilterBottomSheetFromOutside() {
    _openFilterBottomSheet();
  }

  Future<void> _openFilterBottomSheet() async {
    String? tempCountry = _filterCountry;
    String? tempTag = _filterTag;

    // 💡 이제는 Pals에서 추출하지 않고,
    // 매칭 설정과 동일한 고정 목록 사용
    final countries = kFilterCountries;
    final tagCodes = kTagCodeToLabel.keys.toList(); // ['LIFE','STUDY',…]

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '필터 설정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (countries.isNotEmpty) ...[
                    const Text(
                      '국가',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('전체'),
                          selected: tempCountry == null,
                          onSelected: (_) {
                            setModalState(() {
                              tempCountry = null;
                            });
                          },
                        ),
                        for (final c in countries)
                          ChoiceChip(
                            label: Text(c),
                            selected: tempCountry == c,
                            onSelected: (_) {
                              setModalState(() {
                                tempCountry = c;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (tagCodes.isNotEmpty) ...[
                    const Text(
                      '관심 태그',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('전체'),
                          selected: tempTag == null,
                          onSelected: (_) {
                            setModalState(() {
                              tempTag = null;
                            });
                          },
                        ),
                        for (final code in tagCodes)
                          ChoiceChip(
                            // 코드 -> 한글 라벨
                            label: Text(tagLabel(code)),
                            selected: tempTag == code,
                            onSelected: (_) {
                              setModalState(() {
                                tempTag = code;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempCountry = null;
                            tempTag = null;
                          });
                        },
                        child: const Text('초기화'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx, true);
                        },
                        child: const Text('적용'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (applied == true) {
      setState(() {
        _filterCountry = tempCountry;
        _filterTag = tempTag;
        _displayPals = _buildFilteredList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ===== 필터 chip 표시 영역 (배경색 없음) =====
        if (_filterCountry != null || _filterTag != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_filterCountry != null)
                    _ActiveFilterChip(
                      label: '국가: ${_filterCountry!}',
                      onClear: () {
                        setState(() {
                          _filterCountry = null;
                          _displayPals = _buildFilteredList();
                        });
                      },
                    ),
                  if (_filterTag != null)
                    _ActiveFilterChip(
                      // 태그도 한글 라벨로 표시
                      label: '태그: ${tagLabel(_filterTag!)}',
                      onClear: () {
                        setState(() {
                          _filterTag = null;
                          _displayPals = _buildFilteredList();
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

        // ===== 목록 영역 =====
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _displayPals.isEmpty
              ? const Center(
            child: Text(
              '표시할 Pal이 없습니다.\n매칭을 통해 Pal을 늘려보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadPals,
            child: ListView(
              padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Pal LIST',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.black,
                    ),
                  ),
                ),
                ..._displayPals.map(
                      (p) => Padding(
                    padding:
                    const EdgeInsets.only(bottom: 12),
                    child: PalCard(pal: p),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    super.key,
    required this.label,
    required this.onClear,
  });

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PalColors.orange),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close,
              size: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================
///     Pal Card
/// =====================

class PalCard extends StatelessWidget {
  const PalCard({super.key, required this.pal});

  final Pal pal;

  @override
  Widget build(BuildContext context) {
    final locationText =
    pal.regions.isNotEmpty ? pal.regions.join(', ') : pal.country;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO: 여기서 Pal 상세 or 채팅방으로 이동
      },
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: PalColors.orange, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: PalColors.orangeSolid,
                child: Text(
                  pal.initial,
                  style: const TextStyle(
                    color: PalColors.brown,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pal.name,
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (pal.online)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationText,
                      style: const TextStyle(
                        color: PalColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pal.tags
                      // 코드/영문이든 한글이든 tagLabel로 한 번 더 태워서 표시
                          .map((t) => _TagChip(tagLabel(t)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: PalColors.tagRedBg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: PalColors.tagRed,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Open Sans',
        ),
      ),
    );
  }
}

/// =====================
///  Pal 모델 (JSON 매핑)
/// =====================

class Pal {
  final int id;
  final String name;
  final String country;
  final List<String> tags;    // 서버에서 온 "원본" 값 (코드 or 라벨)
  final List<String> regions; // 지역 라벨 (영문/한글 섞여도 OK)
  final bool online;

  Pal({
    required this.id,
    required this.name,
    required this.country,
    List<String>? tags,
    List<String>? regions,
    this.online = false,
  })  : tags = tags ?? const [],
        regions = regions ?? const [];

  String get initial =>
      name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

  factory Pal.fromJson(Map<String, dynamic> json) {
    final idDynamic = json['id'] ?? json['userId'];

    final name = (json['nickname'] ??
        json['username'] ??
        json['name'] ??
        'Unknown')
        .toString();

    final country = (json['country'] ?? '').toString();

    // ---- tags 처리 ----
    List<String> tags = [];

    // 한글/표시용이 `tagNames`라면 이걸 먼저 사용, 없으면 `tags` 사용
    final rawTags = json['tagNames'] ?? json['tags'];

    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    }

    // ---- regions 처리 ----
    List<String> regions = [];
    final rawRegions = json['regions'] ?? json['userRegions'];

    if (rawRegions is List) {
      regions = rawRegions
          .map((e) {
        if (e is Map) {
          // [{ "region": "서울" }, { "region": "인천" }] 이런 케이스
          final r = e['region'] ?? e['name'] ?? e['regionName'];
          return r?.toString() ?? '';
        }
        // ["서울", "인천"] 처럼 문자열 리스트인 케이스
        return e.toString();
      })
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (json['region'] != null) {
      // 단일 region 문자열만 있는 케이스
      regions = [json['region'].toString()];
    }

    final online =
        json['online'] == true || json['isOnline'] == true;

    return Pal(
      id: idDynamic is int
          ? idDynamic
          : int.tryParse(idDynamic.toString()) ?? 0,
      name: name,
      country: country,
      tags: tags,
      regions: regions,
      online: online,
    );
  }
}
