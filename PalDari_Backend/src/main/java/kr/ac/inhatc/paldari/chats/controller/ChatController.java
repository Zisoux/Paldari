package kr.ac.inhatc.paldari.chats.controller;

import kr.ac.inhatc.paldari.chats.entity.ChatMessage;
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
     * 현재 유저의 채팅방 목록 조회 (예시)
     * Flutter: GET /api/chat/rooms
     */
    @GetMapping("/rooms")
    public List<ChatRoomResponse> getMyRooms(Principal principal) {
        String username = principal.getName();

        // TODO: 실제 비즈니스 로직으로 교체
        // 여기서는 "해당 유저가 속한 방" 필터링이 있다고 가정하고,
        // 일단 전체 방을 반환하는 샘플로 둔다.
        return chatRoomRepository.findAll().stream()
                .map(room -> new ChatRoomResponse(
                        room.getId(),
                        room.getName()
                ))
                .collect(Collectors.toList());
    }

    /**
     * 특정 채팅방 메시지 목록 조회 (옵션)
     * Flutter: GET /api/chat/rooms/{roomId}/messages
     */
    @GetMapping("/rooms/{roomId}/messages")
    public List<ChatMessageResponse> getMessages(@PathVariable Long roomId,
                                                 Principal principal) {
        // 필요하면 room 접근 권한 체크
        List<ChatMessage> messages = chatMessageRepository.findByRoom_IdOrderBySentAtAsc(roomId);

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
