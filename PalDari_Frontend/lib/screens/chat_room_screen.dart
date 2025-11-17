import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../config.dart';
import '../providers/auth_provider.dart';
import '../services/api.dart'; // 번역용 ApiService 사용
import 'chat_list_screen.dart'; // 뒤로가기 시 채팅방 리스트로 이동
import 'buddy_rating_screen.dart'; // 버디 평가 화면

class ChatRoomScreen extends StatefulWidget {
  final int roomId;
  final String roomName;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class ChatMessageDto {
  final String type; // TALK / ENTER 등
  final String roomId;
  final String sender;
  final String content;
  final String? sentAt;

  // 클라이언트에서만 사용하는 번역 결과
  String? translatedContent;

  ChatMessageDto({
    required this.type,
    required this.roomId,
    required this.sender,
    required this.content,
    this.sentAt,
    this.translatedContent,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      type: (json['type'] ?? 'TALK').toString(),
      roomId: (json['roomId'] ?? '').toString(),
      sender: (json['sender'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      sentAt: json['sentAt']?.toString(),
    );
  }
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  StompClient? _stompClient;
  bool _connected = false;

  // 🔹 전역 설정과 연동되는 실시간 번역 on/off
  bool _translateEnabled = false;
  bool _showTranslatePanel = false; // 패널 표시 여부 (오른쪽 상단 버튼으로 토글)

  final List<ChatMessageDto> _messages = [];
  final TextEditingController _controller = TextEditingController();

  final ApiService _api = ApiService(); // 공용 API 서비스

  String get _roomTopic => '/topic/chatroom.${widget.roomId}';

  @override
  void initState() {
    super.initState();

    // ✅ 전역 설정(AuthState)에서 초기값 가져오기
    final auth = context.read<AuthState>();
    _translateEnabled = auth.realtimeTranslation ?? false;

    _loadHistory();
    _connect();
  }

  @override
  void dispose() {
    _controller.dispose();
    _stompClient?.deactivate();
    super.dispose();
  }

  // ---------- 과거 메시지 로딩 ----------
  Future<void> _loadHistory() async {
    try {
      final auth = context.read<AuthState>();
      final token = auth.accessToken;

      final res = await http.get(
        Uri.parse('$apiBase/api/chat/rooms/${widget.roomId}/messages'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        final List<dynamic> rawList =
        decoded is List ? List<dynamic>.from(decoded) : [];

        final history = rawList.map((e) {
          final Map<String, dynamic> map = e is Map
              ? Map<String, dynamic>.from(e as Map)
              : (e is String
              ? jsonDecode(e) as Map<String, dynamic>
              : <String, dynamic>{});
          return ChatMessageDto.fromJson(map);
        }).toList(growable: false);

        if (!mounted) return;
        setState(() {
          _messages
            ..clear()
            ..addAll(history);
        });

        // 🔹 번역 토글이 켜져 있으면 기존 메시지도 번역 시도
        if (_translateEnabled) {
          _translateExistingMessages();
        }
      } else {
        debugPrint('loadHistory failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('loadHistory error: $e');
    }
  }

  // 이미 로드된 메시지들을 번역
  Future<void> _translateExistingMessages() async {
    if (!_translateEnabled) return;
    if (!mounted) return;

    final auth = context.read<AuthState>();
    final currentUser = auth.username ?? '';

    final locale = Localizations.localeOf(context);
    final targetLang = locale.languageCode;

    for (final m in _messages) {
      if (m.type != 'TALK') continue;
      if (m.sender == currentUser) continue;
      if (m.translatedContent != null) continue;

      try {
        final translated = await _api.autoTranslate(
          text: m.content,
          targetLang: targetLang,
        );

        if (!mounted) return;
        if (translated == m.content) continue;

        setState(() {
          m.translatedContent = translated;
        });
      } catch (e, st) {
        debugPrint('translateExistingMessages error: $e\n$st');
      }
    }
  }

  // ---------- STOMP 연결 ----------
  void _connect() {
    final auth = context.read<AuthState>();
    final token = auth.accessToken;

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: '$apiBase/ws-chat',
        stompConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        onConnect: _onConnect,
        onWebSocketError: (e) => debugPrint('WS error: $e'),
        onStompError: (f) => debugPrint('STOMP error: ${f.body}'),
        onDisconnect: (_) {
          if (mounted) setState(() => _connected = false);
        },
      ),
    );

    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    if (!mounted) return;
    setState(() => _connected = true);

    _stompClient!.subscribe(
      destination: _roomTopic,
      callback: (frame) {
        if (frame.body == null) return;

        Map<String, dynamic> data;
        try {
          final decoded = jsonDecode(frame.body!);
          data = decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{};
        } catch (e, st) {
          debugPrint('stomp parse json error: $e\n$st');
          return;
        }

        ChatMessageDto msg;
        try {
          msg = ChatMessageDto.fromJson(data);
        } catch (e, st) {
          debugPrint('stomp dto convert error: $e\n$st');
          return;
        }

        // 🔹 새 메시지는 헬퍼로 처리 + 필요시 번역
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleIncomingMessage(msg);
        });
      },
    );

    // 입장 알림
    _stompClient!.send(
      destination: '/app/chat.enter/${widget.roomId}',
      body: jsonEncode({
        'type': 'ENTER',
        'roomId': widget.roomId.toString(),
      }),
    );
  }

  // 새로 도착한 메시지 처리 + 자동 번역
  Future<void> _handleIncomingMessage(ChatMessageDto msg) async {
    if (!mounted) return;

    final auth = context.read<AuthState>();
    final currentUser = auth.username ?? '';

    setState(() {
      _messages.add(msg);
    });

    if (msg.type != 'TALK') return;
    if (msg.sender == currentUser) return;
    if (!_translateEnabled) return;

    try {
      final locale = Localizations.localeOf(context);
      final targetLang = locale.languageCode;

      final translated = await _api.autoTranslate(
        text: msg.content,
        targetLang: targetLang,
      );

      if (!mounted) return;
      if (translated == msg.content) return;

      setState(() {
        msg.translatedContent = translated;
      });
    } catch (e, st) {
      debugPrint('autoTranslate error: $e\n$st');
    }
  }

  // ---------- 메시지 전송 ----------
  void _send() {
    if (!_connected) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    _stompClient!.send(
      destination: '/app/chat.send/${widget.roomId}',
      body: jsonEncode({
        'type': 'TALK',
        'roomId': widget.roomId.toString(),
        'content': text,
      }),
    );
  }

  // ---------- 버디 평가 화면 이동 ----------
  void _openRatingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuddyRatingScreen(
          // TODO: 지금은 임시로 roomId/roomName 기반 값 사용
          buddyId: widget.roomId, // 실제 buddyId로 바꾸기
          chatRoomId: widget.roomId,
          buddyName: widget.roomName,
          buddyImageUrl: '',
          tags: const [],
        ),
      ),
    );
  }

  // ---------- 시간 표시 포맷 ----------
  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) {
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return '$hh:$mm';
      } else {
        return '${dt.month}/${dt.day}';
      }
    } catch (_) {
      return '';
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final currentUser = auth.username ?? '';

    return WillPopScope(
      onWillPop: () async {
        // 시스템 뒤로가기 → 무조건 채팅방 리스트
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ChatListScreen(),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F1),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              if (_showTranslatePanel) _buildTranslateToggle(),
              if (_showTranslatePanel) const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final m = _messages[index];
                    final isMe = m.sender == currentUser;
                    final isEnter = m.type == 'ENTER';

                    if (isEnter) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(
                            m.content.isNotEmpty
                                ? m.content
                                : '${m.sender} joined the room',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.brown.withOpacity(0.5),
                            ),
                          ),
                        ),
                      );
                    }

                    final timeText = _formatTime(m.sentAt);

                    String mainText = m.content;
                    String? originalSubText;

                    if (_translateEnabled &&
                        m.translatedContent != null &&
                        !isMe) {
                      mainText = m.translatedContent!;
                      if (m.translatedContent != m.content) {
                        originalSubText = m.content;
                      }
                    }

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFFFAAD55)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(10),
                                topRight: const Radius.circular(10),
                                bottomLeft: isMe
                                    ? const Radius.circular(10)
                                    : Radius.zero,
                                bottomRight: isMe
                                    ? Radius.zero
                                    : const Radius.circular(10),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    m.sender,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.brown.withOpacity(0.6),
                                    ),
                                  ),
                                Text(
                                  mainText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF260101),
                                  ),
                                ),
                                if (_translateEnabled &&
                                    m.translatedContent != null &&
                                    !isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '번역됨',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color:
                                        Colors.brown.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                if (originalSubText != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '원문: $originalSubText',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                        Colors.brown.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (timeText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                right: 4,
                                bottom: 2,
                              ),
                              child: Text(
                                timeText,
                                style: TextStyle(
                                  fontSize: 8,
                                  color:
                                  Colors.brown.withOpacity(0.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // 상단 화살표 뒤로가기 → 무조건 채팅방 리스트로
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatListScreen(),
                ),
              );
            },
            child: const Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: Color(0xFF734124),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFF39D52),
            child: Text(
              widget.roomName.isNotEmpty
                  ? widget.roomName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Color(0xFF734124),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.roomName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // 버디 평가 버튼
          IconButton(
            icon: const Icon(
              Icons.star_rate_rounded,
              color: Color(0xFFFAAD55),
              size: 24,
            ),
            tooltip: '버디 평가하기',
            onPressed: _openRatingScreen,
          ),
          // 실시간 번역 설정 토글 버튼 (패널 열기/닫기)
          IconButton(
            icon: const Icon(
              Icons.translate,
              color: Color(0xFF734124),
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _showTranslatePanel = !_showTranslatePanel;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTranslateToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5),
            bottomRight: Radius.circular(5),
          ),
          border: Border.all(color: const Color(0xFF734124)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '실시간 번역',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'Open Sans',
              ),
            ),
            Switch(
              value: _translateEnabled,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF34C759),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey,
              onChanged: (bool v) {
                setState(() {
                  _translateEnabled = v;
                });

                // 🔹 전역 설정(AuthState) + 백엔드에 반영
                context
                    .read<AuthState>()
                    .updateSettings(realtimeTranslation: v);

                if (v) {
                  // 켜질 때 기존 메시지도 번역 시도
                  _translateExistingMessages();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            // "+" 버튼
            GestureDetector(
              onTap: () {
                // TODO: 파일/이미지/기능 추가
              },
              child: Container(
                width: 36,
                height: 40,
                alignment: Alignment.center,
                child: const Text(
                  '+',
                  style: TextStyle(
                    color: Color(0xFF734124),
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // 인풋 박스
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 43,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF2F2F2),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: Colors.black.withOpacity(0.5),
                      fontSize: 14,
                      fontFamily: 'Open Sans',
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // 보내기 버튼
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 41,
                height: 43,
                decoration: const BoxDecoration(
                  color: Color(0xFF734124),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: const Icon(
                  Icons.send,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
