import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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

class PalHomeScreen extends StatelessWidget {
  const PalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final username = (auth.profile?['username'] as String?)?.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _PalTopAppBar(username: username),
      ),
      body: const SafeArea(
        top: false,
        child: _PalListSection(),
      ),
      bottomNavigationBar: const _PalBottomNav(currentIndex: 0),
    );
  }
}

class _PalTopAppBar extends StatelessWidget {
  const _PalTopAppBar({this.username});
  final String? username;

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
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            tooltip: 'Settings',
          ),
          if (username != null && username!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PalColors.orange.withOpacity(0.6)),
                ),
                child: Text(
                  "환영합니다, '" + username! + "'님",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PalListSection extends StatelessWidget {
  const _PalListSection();

  @override
  Widget build(BuildContext context) {
    final pals = _mockPals; // Replace with your actual data source.

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        // Section Header
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

        // Cards
        ...pals.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PalCard(pal: p),
        )),
      ],
    );
  }
}

class PalCard extends StatelessWidget {
  const PalCard({super.key, required this.pal});

  final Pal pal;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO: navigate to Pal detail or chat
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
              // Avatar
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

              // Name, Country, Tags
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
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDF6E3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pal.country,
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
                      children: pal.tags.map(_TagChip.new).toList(),
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

class _PalBottomNav extends StatelessWidget {
  const _PalBottomNav({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: Colors.white,
      elevation: 1,
      indicatorColor: PalColors.orange.withOpacity(0.15),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
        NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: '매칭'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: '채팅'),
        NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: '커뮤니티'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '마이페이지'),
      ],
      onDestinationSelected: (i) {
        // TODO: wire navigation or use go_router
      },
    );
  }
}

// ------------------ Mock Data & Model ------------------
class Pal {
  final String name;
  final String country;
  final List<String> tags;
  final bool online;

  Pal({required this.name, required this.country, required this.tags, this.online = false});

  String get initial => name.isNotEmpty ? name.characters.first : '?';
}

final _mockPals = <Pal>[
  Pal(name: 'Mike', country: '미국', tags: ['#생활', '#학업'], online: true),
  Pal(name: 'Sunny', country: '일본', tags: ['#지역', '#안전']),
  Pal(name: 'Alice', country: '캐나다', tags: ['#생활', '#지역']),
  Pal(name: 'Alex', country: '영국', tags: ['#학업', '#안전']),
  Pal(name: 'Aby', country: '영국', tags: ['#생활', '#안전']),
];
