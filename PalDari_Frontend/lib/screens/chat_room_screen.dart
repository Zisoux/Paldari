import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../providers/auth_provider.dart';
import '../config.dart'; // apiBase 사용

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
  final String type;
  final String roomId;
  final String sender;
  final String content;

  ChatMessageDto({
    required this.type,
    required this.roomId,
    required this.sender,
    required this.content,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      type: json['type'] ?? 'TALK',
      roomId: json['roomId'] ?? '',
      sender: json['sender'] ?? '',
      content: json['content'] ?? '',
    );
  }
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  StompClient? _stompClient;
  bool _connected = false;
  final List<ChatMessageDto> _messages = [];
  final TextEditingController _controller = TextEditingController();

  /// 방별 구독 토픽
  String get _roomTopic => '/topic/chatroom.${widget.roomId}';

  /// SockJS 엔드포인트
  /// config.dart의 apiBase 기준으로 생성
  /// - Web:    http://localhost:8080/ws-chat
  /// - Emulator: (apiBase를 10.0.2.2로 쓰면) http://10.0.2.2:8080/ws-chat
  String get _wsUrl => '$apiBase/ws-chat';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    final auth = context.read<AuthState>();
    final token = auth.accessToken;

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: _wsUrl,
        stompConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        onConnect: _onConnect,
        onWebSocketError: (error) {
          debugPrint('WebSocket error: $error');
        },
      ),
    );

    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    setState(() => _connected = true);

    // 채팅방 구독
    _stompClient!.subscribe(
      destination: _roomTopic,
      callback: (frame) {
        if (frame.body == null) return;
        final data = jsonDecode(frame.body!) as Map<String, dynamic>;
        setState(() {
          _messages.add(ChatMessageDto.fromJson(data));
        });
      },
    );

    // 입장 메시지 (옵션)
    _stompClient!.send(
      destination: '/app/chat.enter/${widget.roomId}',
      body: jsonEncode({
        'type': 'ENTER',
        'roomId': widget.roomId.toString(),
      }),
    );
  }

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

  @override
  void dispose() {
    _controller.dispose();
    _stompClient?.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final currentUser = auth.username ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        backgroundColor: const Color(0xFFF39D52),
        foregroundColor: const Color(0xFF734124),
      ),
      body: Column(
        children: [
          // 메시지 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isMe = (m.sender == currentUser);

                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFFF39D52)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Text(
                            m.sender,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        Text(m.content),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 입력창
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                  color: const Color(0xFFF39D52),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
