import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class PalColors {
  PalColors._();
  static const cream = Color(0xFFFFF7F1);
  static const orange = Color(0xFFF29D52);
  static const brown = Color(0xFF734124);
  static const deepBrown = Color(0xFF260101);
  static const textSecondary = Color(0xFF9F9FA1);
  static const danger = Color(0xFFFF5161);
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final username = (auth.profile?['username'] as String?) ?? '';
    final email = (auth.profile?['email'] as String?) ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: PalColors.cream,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PalColors.brown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: ListView(
        children: [
          // 상단 프로필 박스
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: PalColors.cream,
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: PalColors.deepBrown,
                  child: Text(
                    (username.isNotEmpty ? username[0] : '?').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username.isNotEmpty ? username : '로그인 사용자',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: PalColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.08),
                    ),
                  ),
                  child: const Text(
                    '인증됨',
                    style: TextStyle(
                      color: Color(0xFF34C759),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 토글 / 설정 리스트 (더미)
          _sectionHeader('환경 설정'),
          _switchTile(
            title: '알림 허용',
            value: true,
            onChanged: (v) {
              // TODO: 실제 설정 연동
            },
          ),
          _switchTile(
            title: '매칭 허용',
            value: true,
            onChanged: (v) {
              // TODO
            },
          ),
          _switchTile(
            title: '실시간 번역',
            value: false,
            onChanged: (v) {
              // TODO
            },
          ),

          _sectionHeader('앱 정보'),
          _navTile(
            title: '공지사항',
            onTap: () {
              // TODO: 공지사항 화면 이동
            },
          ),
          _navTile(
            title: '고객센터',
            onTap: () {
              // TODO: 고객센터 화면 이동
            },
          ),
          ListTile(
            title: const Text(
              '앱 버전',
              style: TextStyle(fontSize: 15),
            ),
            trailing: const Text(
              'Beta',
              style: TextStyle(
                fontSize: 14,
                color: PalColors.textSecondary,
              ),
            ),
          ),

          const Divider(height: 24, thickness: 0.4),

          // 🔥 로그아웃
          ListTile(
            title: const Center(
              child: Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        '로그아웃',
                        style: TextStyle(color: PalColors.danger),
                      ),
                    ),
                  ],
                ),
              );

              if (ok == true) {
                await context.read<AuthState>().logout();
                // 모든 화면 제거 후 로그인 화면으로
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                        (route) => false,
                  );
                }
              }
            },
          ),

          // 회원탈퇴 (아직 기능 미구현 - UI만)
          ListTile(
            title: const Center(
              child: Text(
                '회원탈퇴',
                style: TextStyle(
                  fontSize: 16,
                  color: PalColors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            onTap: () {
              // TODO: 회원탈퇴 기능 구현 시 연결
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: PalColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _navTile({required String title, VoidCallback? onTap}) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 15),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 15),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: PalColors.orange,
    );
  }
}
