package kr.ac.inhatc.paldari.chats.controller;

import kr.ac.inhatc.paldari.chats.entity.ChatMessage;
import kr.ac.inhatc.paldari.chats.entity.ChatRoom;
import kr.ac.inhatc.paldari.chats.repository.ChatMessageRepository;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomRepository;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/chat")
public class ChatController {

    private final ChatRoomRepository chatRoomRepository;
    private final ChatMessageRepository chatMessageRepository;

    /**
     * 개발용: 모든 유저에게 공통 "개발자 테스트 방" 하나를 항상 반환.
     * Flutter: GET /api/chat/rooms
     */
    @GetMapping("/rooms")
    public List<ChatRoomResponse> getMyRooms(Principal principal) {
        // 일단 인증은 SecurityConfig에서 처리된다고 가정.
        // principal.getName() 쓰면 "누가 접속했는지" 확인 가능 (로그용).

        // 1. DEV_TEST_ROOM 이라는 내부용 채팅방이 없으면 생성
        ChatRoom devRoom = chatRoomRepository.findByName("DEV_TEST_ROOM")
                .orElseGet(() -> {
                    ChatRoom room = new ChatRoom();
                    room.setName("DEV_TEST_ROOM");
                    return chatRoomRepository.save(room);
                });

        // 2. 프론트에는 보기 좋게 label만 바꿔서 전달
        return List.of(
                new ChatRoomResponse(devRoom.getId(), "개발자 테스트 방")
        );
    }

    /**
     * 특정 채팅방 메시지 목록 조회
     * Flutter: GET /api/chat/rooms/{roomId}/messages
     */
    @GetMapping("/rooms/{roomId}/messages")
    public List<ChatMessageResponse> getMessages(@PathVariable Long roomId,
                                                 Principal principal) {

        // TODO: 필요하다면 여기서 room 접근 권한 체크

        // 네가 만든 메서드 이름에 맞춰 사용 (findByRoomIdOrderBySentAtAsc)
        List<ChatMessage> messages =
                chatMessageRepository.findByRoomIdOrderBySentAtAsc(roomId);

        return messages.stream()
                .map(m -> new ChatMessageResponse(
                        m.getId(),
                        m.getRoom().getId(),
                        m.getSender(),
                        m.getContent(),
                        m.getType().name(),
                        m.getSentAt().toString()
                ))
                .collect(Collectors.toList());
    }

    // ====== DTO ======

    @Data
    @AllArgsConstructor
    public static class ChatRoomResponse {
        private Long id;
        private String name;
    }

    @Data
    @AllArgsConstructor
    public static class ChatMessageResponse {
        private Long id;
        private Long roomId;
        private String sender;
        private String content;
        private String type;
        private String sentAt;
    }
}
