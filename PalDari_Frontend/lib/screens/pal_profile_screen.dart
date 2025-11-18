// lib/screens/pal_profile_screen.dart
import 'package:flutter/material.dart';
import '../screens/home_screen.dart' show Pal, PalColors;
import '../services/api.dart';

class PalProfileScreen extends StatelessWidget {
  final Pal pal;

  const PalProfileScreen({
    Key? key,
    required this.pal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 화면 폭 넓을 때를 대비한 컨테이너 (마이페이지랑 톤 비슷하게)
    return Scaffold(
      backgroundColor: PalColors.cream,
      appBar: AppBar(
        backgroundColor: PalColors.cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: PalColors.brown),
        title: Text(
          pal.name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ===== 상단 프로필 영역 (아바타 + 이름 + 국가) =====
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: PalColors.orangeSolid,
                            child: Text(
                              pal.initial,
                              style: const TextStyle(
                                color: PalColors.brown,
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
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
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
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
                                  pal.country.isEmpty ? '국가 미설정' : pal.country,
                                  style: const TextStyle(
                                    color: PalColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Open Sans',
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(),

                      // ===== 관심 태그 섹션 =====
                      const Text(
                        '관심 태그',
                        style: TextStyle(
                          color: PalColors.brown,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      pal.tags.isEmpty
                          ? const Text(
                        '등록된 태그가 없습니다.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      )
                          : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: pal.tags
                            .map(
                              (t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: PalColors.tagRedBg,
                              borderRadius:
                              BorderRadius.circular(100),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                color: PalColors.tagRed,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                          ),
                        )
                            .toList(),
                      ),

                      const SizedBox(height: 20),
                      const Divider(),

                      // ===== 향후 확장 영역 (언어, 소개, 지역, 평점 등) =====
                      const Text(
                        '추가 정보',
                        style: TextStyle(
                          color: PalColors.brown,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '지금은 홈에서 받은 기본 정보만 보여주고 있어요.\n'
                            '나중에 백엔드에서 공개 프로필 API를 만들면 '
                            '구사 언어, 활동 지역, 자기소개, 평점 등을 여기서 함께 보여줄 수 있어요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 채팅 시작 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          onPressed: () async {
                            // 🔥 Pal.id 가 백엔드의 userId / memberId 와 매핑된다고 가정
                            final api = ApiService();

                            try {
                              // 채팅방 생성 / 기존 방 조회
                              final room = await api.createChatForMatching(
                                targetUserId: pal.id,
                              );

                              // TODO: 채팅 화면으로 바로 이동하고 싶다면
                              // Navigator.push(...) 로 ChatScreen 에 room 정보 전달
                              // 예) Navigator.pushNamed(context, '/chat-room', arguments: room);

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '채팅방이 준비됐어요! 채팅 탭에서 확인해 주세요. (roomId: ${room['roomId']})',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '채팅방 생성 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.',
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PalColors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          label: const Text(
                            '채팅 시작하기',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                    ],
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
