import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config.dart';
import '../providers/auth_provider.dart';
import '../widgets/pal_bottom_nav.dart';
import 'chat_room_screen.dart';
import 'home_screen.dart';

class ChatRoomSummary {
  final int roomId;
  final String name;
  final String subText;
  final int unreadCount;

  /// ⭐ 이 채팅방에서 대화하는 상대방의 userId (users.id)
  final int buddyUserId;

  ChatRoomSummary({
    required this.roomId,
    required this.name,
    required this.subText,
    required this.unreadCount,
    required this.buddyUserId,
  });

  factory ChatRoomSummary.fromJson(Map<String, dynamic> json) {
    // 백엔드 ChatRoomResponse: { roomId, name, buddyUserId, ... }
    final id = json['roomId'] ?? json['id'];

    // ⭐ 상대 유저의 userId 매핑
    //   기본: buddyUserId
    //   백업: buddyId / targetUserId (백엔드 필드명이 다를 경우 대비)
    final buddyRaw =
        json['buddyUserId'] ?? json['buddyId'] ?? json['targetUserId'];
    final buddyUserId = buddyRaw is int
        ? buddyRaw
        : int.tryParse(buddyRaw?.toString() ?? '') ?? 0;

    return ChatRoomSummary(
      roomId: id is int ? id : int.tryParse(id.toString()) ?? 0,
      name: json['name'] ?? 'Unknown',
      subText: json['subText'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      buddyUserId: buddyUserId,
    );
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<ChatRoomSummary>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _fetchRooms();
  }

  Future<List<ChatRoomSummary>> _fetchRooms() async {
    final auth = context.read<AuthState>();
    final token = auth.accessToken;

    try {
      final res = await http.get(
        Uri.parse('$apiBase/api/chat/rooms'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // debugPrint('GET /api/chat/rooms => ${res.statusCode} ${res.body}');

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List;
        return data
            .map((e) => ChatRoomSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('Failed to load rooms: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Error fetching rooms: $e');
    }

    // 실패 시: 빈 리스트 반환 (UI에서 "채팅방이 없습니다" 표시)
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PalColors.cream,
      appBar: _buildTopBar(),
      bottomNavigationBar: const PalBottomNav(currentIndex: 2),
      body: FutureBuilder<List<ChatRoomSummary>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('채팅방을 불러올 수 없습니다.'));
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return const Center(
              child: Text(
                '채팅방이 없습니다.\n매칭을 통해 새로운 채팅을 시작해 보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.black.withOpacity(0.05),
            ),
            itemBuilder: (context, index) {
              final r = rooms[index];
              return _buildRoomTile(r);
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildTopBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: PalColors.cream,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Chats',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage('https://placehold.co/25x25/png'),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: Colors.black.withOpacity(0.05),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildRoomTile(ChatRoomSummary room) {
    final initial = room.name.isNotEmpty
        ? room.name.characters.first.toUpperCase()
        : '?';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              roomId: room.roomId,
              buddyUserId: room.buddyUserId, // ⭐ 상대 userId 전달
              roomName: room.name,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: PalColors.orangeSolid,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: PalColors.brown),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: PalColors.brown,
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (room.subText.isNotEmpty)
                    Text(
                      room.subText,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.5),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                ],
              ),
            ),
            if (room.unreadCount > 0)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5161),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${room.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
