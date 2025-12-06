import 'dart:convert';
import 'package:characters/characters.dart'; // ✅ characters extension 안전하게
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paldari/services/api.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../providers/auth_provider.dart';
import '../widgets/pal_bottom_nav.dart';
import 'chat_room_screen.dart';
import 'home_screen.dart'; // ✅ PalColors 여기서 가져온다고 했던 원본 구조 유지

class ChatRoomSummary {
  final int roomId;
  final String name;
  final String subText;
  final int unreadCount;
  final int buddyUserId;

  ChatRoomSummary({
    required this.roomId,
    required this.name,
    required this.subText,
    required this.unreadCount,
    required this.buddyUserId,
  });

  factory ChatRoomSummary.fromJson(Map<String, dynamic> json) {
    final id = json['roomId'] ?? json['id'];

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

  bool _selectMode = false;
  final Set<int> _selectedRoomIds = {};
  bool _deleting = false;

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
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

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
    return [];
  }

  void _refreshRooms() {
    setState(() {
      _roomsFuture = _fetchRooms();
    });
  }


  void _enterSelectMode({int? selectRoomId}) {
    setState(() {
      _selectMode = true;
      if (selectRoomId != null) _selectedRoomIds.add(selectRoomId);
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selectedRoomIds.clear();
    });
  }

  void _toggleSelect(int roomId) {
    setState(() {
      if (_selectedRoomIds.contains(roomId)) {
        _selectedRoomIds.remove(roomId);
        if (_selectedRoomIds.isEmpty) _selectMode = false;
      } else {
        _selectedRoomIds.add(roomId);
        _selectMode = true;
      }
    });
  }

  Future<bool> _deleteRoomOnServer(int roomId) async {
    try {
      await ApiService().leaveChatRoom(roomId);
      return true;
    } catch (e) {
      debugPrint('Delete error roomId=$roomId => $e');
      return false;
    }
  }


  Future<void> _confirmAndDeleteSelected() async {
    if (_selectedRoomIds.isEmpty || _deleting) return;

    final count = _selectedRoomIds.length;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('채팅방을 나가시겠습니까?'),
        content: Text(
          count == 1
              ? '선택한 채팅방에서 나가며 목록에서 삭제됩니다.'
              : '선택한 $count개의 채팅방에서 나가며 목록에서 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _deleting = true);

    int success = 0;
    int fail = 0;

    final ids = _selectedRoomIds.toList();
    for (final roomId in ids) {
      final ok = await _deleteRoomOnServer(roomId);
      if (ok) {
        success++;
      } else {
        fail++;
      }
    }

    if (!mounted) return;
    setState(() => _deleting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fail == 0 ? '채팅방 $success개를 삭제했어요.' : '삭제 성공 $success개 / 실패 $fail개',
        ),
      ),
    );

    _exitSelectMode();
    _refreshRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PalColors.cream,
      appBar: _buildTopBar(),
      bottomNavigationBar: const PalBottomNav(currentIndex: 2),
      body: Stack(
        children: [
          FutureBuilder<List<ChatRoomSummary>>(
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
                    style: TextStyle(color: Colors.black54, fontSize: 15),
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
                  final selected = _selectedRoomIds.contains(r.roomId);
                  return _buildRoomTile(r, selected: selected);
                },
              );
            },
          ),
          if (_deleting)
            Container(
              color: Colors.black.withOpacity(0.15),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopBar() {
    final selectedCount = _selectedRoomIds.length;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: PalColors.cream,
      elevation: 0,
      centerTitle: true,
      title: Text(
        _selectMode ? '선택 ($selectedCount)' : 'Chats',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (_selectMode) ...[
          IconButton(
            tooltip: '삭제(나가기)',
            onPressed: selectedCount == 0
                ? null
                : () => _confirmAndDeleteSelected(), // ✅ async 콜백 래핑
            icon: const Icon(Icons.delete_outline, color: Colors.black),
          ),
          IconButton(
            tooltip: '취소',
            onPressed: _exitSelectMode,
            icon: const Icon(Icons.close, color: Colors.black),
          ),
        ] else ...[
          IconButton(
            tooltip: '편집',
            onPressed: () => _enterSelectMode(),
            icon: const Icon(Icons.checklist, color: Colors.black),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage('https://placehold.co/25x25/png'),
            ),
          ),
        ],
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

  Widget _buildRoomTile(ChatRoomSummary room, {required bool selected}) {
    final initial = room.name.isNotEmpty
        ? room.name.characters.first.toString().toUpperCase()
        : '?';

    return InkWell(
      onLongPress: () => _enterSelectMode(selectRoomId: room.roomId),
      onTap: () {
        if (_selectMode) {
          _toggleSelect(room.roomId);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              roomId: room.roomId,
              buddyUserId: room.buddyUserId,
              roomName: room.name,
            ),
          ),
        );
      },
      child: Container(
        color: selected ? const Color(0x1AF29D52) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            if (_selectMode) ...[
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? PalColors.orangeSolid : Colors.black26,
              ),
              const SizedBox(width: 12),
            ],
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
            if (!_selectMode && room.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
