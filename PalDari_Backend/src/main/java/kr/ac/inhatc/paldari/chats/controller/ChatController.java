package kr.ac.inhatc.paldari.chats.controller;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.chats.dto.ChatRoomResponse;
import kr.ac.inhatc.paldari.chats.entity.ChatMessage;
import kr.ac.inhatc.paldari.chats.repository.ChatMessageRepository;
import kr.ac.inhatc.paldari.chats.service.ChatService;
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

    private final ChatMessageRepository chatMessageRepository;
    private final ChatService chatService;
    private final UserRepository userRepository;   // 🔹 currentUserId에서 사용

    /**
     * 내가 속한 채팅방 목록
     * GET /api/chat/rooms
     */
    @GetMapping("/rooms")
    public List<ChatRoomResponse> getMyRooms(Authentication authentication) {
        Long meId = currentUserId(authentication);   // 🔹 공통 헬퍼 사용
        return chatService.getMyRooms(meId);
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
     * Authentication에서 username을 꺼내서 "DB상의 user PK(id)"로 변환
     * - name 이 "1113" 같은 username이면: username 기준으로 찾고 → id 반환
     * - name 이 "3" 같은 PK 문자열이면: id로 찾고 → id 반환
     */
    private Long currentUserId(Authentication authentication) {
        if (authentication == null) {
            throw new IllegalStateException("인증 정보가 없습니다.");
        }

        String name = authentication.getName(); // "1113" 또는 "3" 등

        // 1) username 기준으로 먼저 조회 (우리 user 테이블에서 username=1113)
        var byUsername = userRepository.findByUsername(name);
        if (byUsername.isPresent()) {
            return byUsername.get().getId();    // 실제 PK (예: 3)
        }

        // 2) username으로도 못 찾으면, 숫자로 파싱 → id 기준으로 조회
        try {
            Long id = Long.parseLong(name);
            User user = userRepository.findById(id)
                    .orElseThrow(() ->
                            new IllegalStateException("사용자를 찾을 수 없습니다: " + name));
            return user.getId();
        } catch (NumberFormatException e) {
            throw new IllegalStateException("사용자를 찾을 수 없습니다: " + name);
        }
    }

    // ====== DTO ======

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
