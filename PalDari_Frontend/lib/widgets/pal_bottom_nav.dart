import 'package:flutter/material.dart';

import '../screens/home_screen.dart' show PalColors;

class PalBottomNav extends StatelessWidget {
  const PalBottomNav({required this.currentIndex, super.key});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: Colors.white,
      elevation: 1,
      indicatorColor: PalColors.orange.withOpacity(0.15),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '홈',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: '매칭',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: '채팅',
        ),
        NavigationDestination(
          icon: Icon(Icons.forum_outlined),
          selectedIcon: Icon(Icons.forum),
          label: '커뮤니티',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '마이페이지',
        ),
      ],
      onDestinationSelected: (index) {
        if (index == currentIndex) return;

        switch (index) {
          case 0: // 홈
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 2: // 채팅
            Navigator.pushReplacementNamed(context, '/chats');
            break;
          case 3: // 커뮤니티
            Navigator.pushReplacementNamed(context, '/posts');
            break;
          case 4: // 마이페이지
            Navigator.pushReplacementNamed(context, '/myPage');
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('아직 준비 중인 메뉴입니다.')),
            );
        }
      },
    );
  }
}
