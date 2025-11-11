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
    final rawEnabled = auth.profile?['enabled'];
    final enabled =
        rawEnabled == true || rawEnabled == 1 || rawEnabled == 'true';

    // ✅ null-safe 기본값 적용
    final allowNotification = auth.allowNotification ?? true;
    final allowMatching = auth.allowMatching ?? true;
    final realtimeTranslation = auth.realtimeTranslation ?? false;

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
          // 상단 프로필
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.08),
                    ),
                  ),
                  child: Text(
                    enabled ? '인증됨' : '인증 전',
                    style: TextStyle(
                      color:
                      enabled ? const Color(0xFF34C759) : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 환경 설정
          _sectionHeader('환경 설정'),
          _switchTile(
            title: '알림 허용',
            value: allowNotification,
            onChanged: (v) {
              context.read<AuthState>().updateSettings(
                allowNotification: v,
              );
            },
          ),
          _switchTile(
            title: '매칭 허용',
            value: allowMatching,
            onChanged: (v) {
              context.read<AuthState>().updateSettings(
                allowMatching: v,
              );
            },
          ),
          _switchTile(
            title: '실시간 번역',
            value: realtimeTranslation,
            onChanged: (v) {
              context.read<AuthState>().updateSettings(
                realtimeTranslation: v,
              );
            },
          ),

          // 앱 정보
          _sectionHeader('앱 정보'),
          _navTile(title: '공지사항', onTap: () {}),
          _navTile(title: '고객센터', onTap: () {}),
          ListTile(
            title: const Text('앱 버전', style: TextStyle(fontSize: 15)),
            trailing: const Text(
              'Beta',
              style: TextStyle(
                fontSize: 14,
                color: PalColors.textSecondary,
              ),
            ),
          ),

          const Divider(height: 24, thickness: 0.4),

          // 로그아웃
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

          // 회원탈퇴
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
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('회원탈퇴'),
                  content:
                  const Text('정말 탈퇴하시겠습니까? 모든 데이터가 삭제됩니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        '회원탈퇴',
                        style: TextStyle(color: PalColors.danger),
                      ),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                final success =
                await context.read<AuthState>().withdrawAccount();
                if (success && context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                        (route) => false,
                  );
                } else {
                  final msg = context.read<AuthState>().error ??
                      '회원탈퇴에 실패했습니다.';
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                }
              }
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
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

  Widget _navTile({required String title, VoidCallback? onTap}) => ListTile(
    title: Text(title, style: const TextStyle(fontSize: 15)),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: onTap,
  );

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 15)),
        value: value,
        onChanged: onChanged,
        activeColor: PalColors.orange,
      );
}
