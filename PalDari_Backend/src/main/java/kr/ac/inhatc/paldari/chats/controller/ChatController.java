package kr.ac.inhatc.paldari.chats.controller;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.chats.entity.ChatMessage;
import kr.ac.inhatc.paldari.chats.entity.ChatRoom;
import kr.ac.inhatc.paldari.chats.repository.ChatMessageRepository;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomMemberRepository;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomRepository;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/chat")
public class ChatController {

    private final ChatRoomRepository chatRoomRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final ChatRoomMemberRepository chatRoomMemberRepository;
    private final UserRepository userRepository;    // 🔹 currentUserId에서 사용

    /**
     * 내가 속한 채팅방 목록
     * GET /api/chat/rooms
     */
    @GetMapping("/rooms")
    public List<ChatRoomResponse> getMyRooms(Authentication authentication) {
        Long meId = currentUserId(authentication);   // 🔹 여기서 헬퍼 사용

        List<ChatRoom> rooms = chatRoomMemberRepository.findRoomsByUserId(meId);

        return rooms.stream()
                .map(r -> new ChatRoomResponse(
                        r.getId(),
                        r.getName(),
                        r.getSubText() != null ? r.getSubText() : ""
                ))
                .collect(Collectors.toList());
    }

    /**
     * 특정 채팅방 메시지 목록 조회
     * GET /api/chat/rooms/{roomId}/messages
     */
    @GetMapping("/rooms/{roomId}/messages")
    public List<ChatMessageResponse> getMessages(@PathVariable Long roomId,
                                                 Authentication authentication) {

        // 필요하다면 여기서도 room 접근 권한 체크 가능 (meId + room 멤버 여부)
        // Long meId = currentUserId(authentication);

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

    // ====== 공통 헬퍼 메서드 ======

    /**
     * Authentication에서 username을 꺼내서 User id로 변환
     * (MatchingController에 이미 있는 currentUserId와 동일한 방식으로 맞춰줘)
     */
    private Long currentUserId(Authentication authentication) {
        if (authentication == null) {
            throw new IllegalStateException("인증 정보가 없습니다.");
        }

        String name = authentication.getName(); // "3" 또는 "admin" 같은 값

        // 1) 먼저 숫자로 파싱을 시도해보고
        try {
            return Long.parseLong(name);
        } catch (NumberFormatException ignored) {
            // 2) 안 되면 -> username 으로 DB 조회
            return userRepository.findByUsername(name)
                    .orElseThrow(() ->
                            new IllegalStateException("사용자를 찾을 수 없습니다: " + name))
                    .getId();
        }
    }

    // ====== DTO ======

    @Data
    @AllArgsConstructor
    public static class ChatRoomResponse {
        private Long id;
        private String name;
        private String subText;   // 🔹 Flutter에서 쓰고 있으니 포함
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
