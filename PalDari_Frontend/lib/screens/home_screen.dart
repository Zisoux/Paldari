// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:paldari/screens/settings_screen.dart';
import 'package:paldari/screens/pal_profile_screen.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api.dart';
import '../widgets/pal_bottom_nav.dart';

/// PalDari Home Screen

class PalColors {
  PalColors._();
  static const cream = Color(0xFFFFF7F1);
  static const orange = Color(0xFFF29D52);
  static const orangeSolid = Color(0xFFF39D52);
  static const brown = Color(0xFF734124);
  static const deepBrown = Color(0xFF260101);
  static const tagRed = Color(0xFFF13855);
  static const tagRedBg = Color(0x35FF5161);
  static const textSecondary = Color(0xFF9F9FA1);
}

const Map<String, String> kTagCodeToLabel = {
  'LIFE': '생활',
  'STUDY': '학업',
  'REGION': '지역',
  'JOB': '취업',
  'SAFETY': '안전',
};

/// user_countries 의 국가 코드 기준 (백엔드랑 맞춰서 사용)
const Map<String, String> kCountryCodeToLabel = {
  'MY': '말레이시아',
  'KR': '한국',
  'JP': '일본',
  'US': '미국',
  'CA': '캐나다',
  'AU': '호주',
  'UK': '영국',
  'DE': '독일',
  'FR': '프랑스',
};

/// 필터에서 사용할 국가코드 리스트
const List<String> kFilterCountryCodes = [
  'MY',
  'KR',
  'JP',
  'US',
  'CA',
  'AU',
  'UK',
  'DE',
  'FR',
];

String countryLabel(String code) => kCountryCodeToLabel[code] ?? code;

String tagLabel(String value) {
  if (kTagCodeToLabel.containsKey(value)) return kTagCodeToLabel[value]!;
  if (kTagCodeToLabel.containsValue(value)) return value;
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
    final auth = context.watch<AuthState>();
    final _ = auth.profile;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _PalTopAppBar(
          onFilterTap: () =>
              _listKey.currentState?.openFilterBottomSheetFromOutside(),
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
  const _PalTopAppBar({required this.onFilterTap});

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
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
          ),
          IconButton(
            onPressed: onFilterTap,
            icon: const Icon(Icons.tune, color: Colors.black87),
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

  String? _filterCountryCode; // 국가코드 (KR, JP, ...)
  String? _filterTag;         // 태그 코드 (LIFE, JOB, ...)

  bool get _hasFilter => _filterCountryCode != null || _filterTag != null;

  @override
  void initState() {
    super.initState();
    _loadPals();
  }

  Future<void> _loadPals() async {
    setState(() => _loading = true);
    try {
      final raw = await _api.fetchHomePals();
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
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ✅ AND 조건으로 필터링
  /// - 국가만 선택되면: 해당 국가코드 포함한 Pal만
  /// - 태그만 선택되면: 해당 태그 포함한 Pal만
  /// - 둘 다 선택되면: 두 조건 모두 만족하는 Pal만
  List<Pal> _buildFilteredList() {
    if (!_hasFilter) {
      // 필터 없으면 원본 그대로 (정렬도 그대로)
      return List<Pal>.from(_allPals);
    }

    bool matches(Pal p) {
      if (_filterCountryCode != null &&
          !p.countries.contains(_filterCountryCode)) {
        return false;
      }
      if (_filterTag != null && !p.tags.contains(_filterTag)) {
        return false;
      }
      return true;
    }

    final result = _allPals.where(matches).toList();
    // 필요하면 여기에서 정렬 기준 더 추가 가능 (ex: online 우선 등)
    return result;
  }

  void openFilterBottomSheetFromOutside() {
    _openFilterBottomSheet();
  }

  Future<void> _openFilterBottomSheet() async {
    String? tempCountryCode = _filterCountryCode;
    String? tempTag = _filterTag;

    final tagCodes = kTagCodeToLabel.keys.toList();

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
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

                    // ---------- 국가 ----------
                    const Text(
                      '국가',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ChoiceChip(
                          label: const Text('전체'),
                          selected: tempCountryCode == null,
                          onSelected: (_) {
                            setModalState(() => tempCountryCode = null);
                          },
                        ),
                        for (final code in kFilterCountryCodes)
                          ChoiceChip(
                            label: Text(countryLabel(code)),
                            selected: tempCountryCode == code,
                            onSelected: (_) {
                              setModalState(() => tempCountryCode = code);
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ---------- 관심 태그 ----------
                    const Text(
                      '관심 태그',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ChoiceChip(
                          label: const Text('전체'),
                          selected: tempTag == null,
                          onSelected: (_) {
                            setModalState(() => tempTag = null);
                          },
                        ),
                        for (final code in tagCodes)
                          ChoiceChip(
                            label: Text(tagLabel(code)),
                            selected: tempTag == code,
                            onSelected: (_) {
                              setModalState(() => tempTag = code);
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempCountryCode = null;
                              tempTag = null;
                            });
                          },
                          child: const Text('초기화'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('적용'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (applied == true) {
      setState(() {
        _filterCountryCode = tempCountryCode;
        _filterTag = tempTag;
        _displayPals = _buildFilteredList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_filterCountryCode != null || _filterTag != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_filterCountryCode != null)
                    _ActiveFilterChip(
                      label: '국가: ${countryLabel(_filterCountryCode!)}',
                      onClear: () {
                        setState(() {
                          _filterCountryCode = null;
                          _displayPals = _buildFilteredList();
                        });
                      },
                    ),
                  if (_filterTag != null)
                    _ActiveFilterChip(
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

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _displayPals.isEmpty
              ? const Center(
            child: Text(
              '표시할 Pal이 없습니다.\n매칭을 통해 Pal을 늘려보세요!',
              textAlign: TextAlign.center,
              style:
              TextStyle(color: Colors.black54, fontSize: 14),
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadPals,
            child: ListView(
              padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                const Padding(
                  padding:
                  EdgeInsets.symmetric(vertical: 8.0),
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
  const _ActiveFilterChip({required this.label, required this.onClear});

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
            child: const Icon(Icons.close, size: 14, color: Colors.black54),
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
  const PalCard({required this.pal});

  final Pal pal;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];

    // 국가코드 → 라벨로 표시
    if (pal.countries.isNotEmpty) {
      parts.add(
        pal.countries.map(countryLabel).join(', '),
      );
    }

    if (pal.languages.isNotEmpty) {
      parts.add(pal.languages.join(', '));
    }

    final locationText =
    parts.isEmpty ? '국가/언어 미설정' : parts.join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PalProfileScreen(pal: pal),
          ),
        );
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
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                      children: pal.tags
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
///  Pal 모델
/// =====================

class Pal {
  final int id;
  final String name;
  final List<String> countries; // 국가코드 리스트 (user_countries 기반)
  final List<String> tags;
  final List<String> regions;
  final bool online;
  final String livingIn;
  final List<String> languages;

  Pal({
    required this.id,
    required this.name,
    required this.countries,
    List<String>? tags,
    List<String>? regions,
    this.online = false,
    this.livingIn = '',
    List<String>? languages,
  })  : tags = tags ?? const [],
        regions = regions ?? const [],
        languages = languages ?? const [];

  String get initial =>
      name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

  factory Pal.fromJson(Map<String, dynamic> json) {
    final idDynamic = json['id'] ?? json['userId'];

    final name = (json['nickname'] ??
        json['username'] ??
        json['name'] ??
        'Unknown')
        .toString();

    // 국가코드: user_countries → countries 로 내려온다고 가정
    List<String> countries = [];
    final rawCountries =
        json['countries'] ?? json['userCountries'] ?? json['country'];
    if (rawCountries is List) {
      countries = rawCountries.map((e) => e.toString()).toList();
    } else if (rawCountries is String && rawCountries.isNotEmpty) {
      countries = rawCountries
          .split(',')
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // tags
    List<String> tags = [];
    final rawTags = json['tagNames'] ?? json['tags'];
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    } else if (rawTags is String && rawTags.isNotEmpty) {
      tags = rawTags
          .split(',')
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // regions (지금은 필터에는 안 쓰지만, 카드 등에서 필요할 수도 있어서 유지)
    List<String> regions = [];
    final rawRegions = json['regions'] ?? json['userRegions'];
    if (rawRegions is List) {
      regions = rawRegions
          .map((e) {
        if (e is Map) {
          return (e['region'] ??
              e['name'] ??
              e['regionName'])
              .toString();
        }
        return e.toString();
      })
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (rawRegions is String && rawRegions.isNotEmpty) {
      regions = rawRegions
          .split(',')
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final online =
        json['online'] == true || json['isOnline'] == true;

    final livingIn = (json['livingIn'] ?? '').toString();

    List<String> languages = [];
    final rawLang = json['languages'];
    if (rawLang is List) {
      languages = rawLang.map((e) => e.toString()).toList();
    } else if (rawLang is String && rawLang.isNotEmpty) {
      languages =
          rawLang.split(',').map((e) => e.trim()).toList();
    }

    return Pal(
      id: idDynamic is int
          ? idDynamic
          : int.tryParse(idDynamic.toString()) ?? 0,
      name: name,
      countries: countries,
      tags: tags,
      regions: regions,
      online: online,
      livingIn: livingIn,
      languages: languages,
    );
  }
}
