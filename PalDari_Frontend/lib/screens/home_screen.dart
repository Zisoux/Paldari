// ===============================
// 변경된 코드 전체 (필요한 부분만 수정)
// ===============================

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
          onFilterTap: () => _listKey.currentState?.openFilterBottomSheetFromOutside(),
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
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ));
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

  String? _filterCountry;
  String? _filterTag;

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

  List<Pal> _buildFilteredList() {
    final list = List<Pal>.from(_allPals);

    int score(Pal p) {
      int s = 0;

      // 🔥 국가 필터 변경 (countries List 기준)
      if (_filterCountry != null &&
          p.countries.contains(_filterCountry)) {
        s += 2;
      }

      if (_filterTag != null && p.tags.contains(_filterTag)) {
        s += 1;
      }

      return s;
    }

    list.sort((a, b) => score(b).compareTo(score(a)));
    return list;
  }

  void openFilterBottomSheetFromOutside() => _openFilterBottomSheet();

  Future<void> _openFilterBottomSheet() async {
    String? tempCountry = _filterCountry;
    String? tempTag = _filterTag;

    final countries = kFilterCountries;
    final tagCodes = kTagCodeToLabel.keys.toList();

    final applied = await showModalBottomSheet<bool>(
      context: context,
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
                  const Text('필터 설정',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  const Text('국가', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('전체'),
                        selected: tempCountry == null,
                        onSelected: (_) {
                          setModalState(() => tempCountry = null);
                        },
                      ),
                      for (final c in countries)
                        ChoiceChip(
                          label: Text(c),
                          selected: tempCountry == c,
                          onSelected: (_) {
                            setModalState(() => tempCountry = c);
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text('관심 태그', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
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
                            tempCountry = null;
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
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadPals,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
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
                    padding: const EdgeInsets.only(bottom: 12),
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
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
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
    // 🔥 변경됨: Pal.country → Pal.countries
    final parts = <String>[];
    if (pal.countries.isNotEmpty) {
      parts.add(pal.countries.join(', '));
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
          MaterialPageRoute(builder: (_) => PalProfileScreen(pal: pal)),
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
                      children:
                      pal.tags.map((t) => _TagChip(tagLabel(t))).toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
  final List<String> countries;   // 🔥 변경됨
  final List<String> tags;
  final List<String> regions;
  final bool online;
  final String livingIn;
  final List<String> languages;

  Pal({
    required this.id,
    required this.name,
    required this.countries,   // 🔥 변경됨
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

    // 🔥 국가 다중 처리
    List<String> countries = [];
    if (json['countries'] is List) {
      countries = (json['countries'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (json['country'] != null) {
      countries = [json['country'].toString()];
    }

    // ---- tags
    List<String> tags = [];
    final rawTags = json['tagNames'] ?? json['tags'];
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    }

    // ---- regions
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
    }

    final online =
        json['online'] == true || json['isOnline'] == true;

    final livingIn = (json['livingIn'] ?? '').toString();

    List<String> languages = [];
    final rawLang = json['languages'];
    if (rawLang is List) {
      languages = rawLang.map((e) => e.toString()).toList();
    } else if (rawLang is String && rawLang.isNotEmpty) {
      languages = rawLang.split(',').map((e) => e.trim()).toList();
    }

    return Pal(
      id: idDynamic is int ? idDynamic : int.tryParse(idDynamic.toString()) ?? 0,
      name: name,
      countries: countries,   // 🔥 변경됨
      tags: tags,
      regions: regions,
      online: online,
      livingIn: livingIn,
      languages: languages,
    );
  }
}
