package kr.ac.inhatc.paldari.chats.controller;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.chats.dto.ChatRoomResponse;
import kr.ac.inhatc.paldari.chats.entity.ChatMessage;
import kr.ac.inhatc.paldari.chats.entity.ChatRoomMember;
import kr.ac.inhatc.paldari.chats.repository.ChatMessageRepository;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomMemberRepository;
import kr.ac.inhatc.paldari.chats.service.ChatService;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/chat")
public class ChatController {

    private final ChatMessageRepository chatMessageRepository;
    private final ChatRoomMemberRepository chatRoomMemberRepository;   // ⭐ 추가됨
    private final ChatService chatService;
    private final UserRepository userRepository;

    /**
     * 내가 속한 채팅방 목록
     * GET /api/chat/rooms
     */
    @GetMapping("/rooms")
    public List<ChatRoomResponse> getMyRooms(Authentication authentication) {
        Long meId = currentUserId(authentication);
        return chatService.getMyRooms(meId);
    }

    /**
     * 채팅방 읽음 처리
     * PATCH /api/chat/rooms/{roomId}/read
     */
    @PatchMapping("/rooms/{roomId}/read")
    public void markAsRead(
            @PathVariable Long roomId,
            Authentication authentication
    ) {
        Long meId = currentUserId(authentication);
        // ⭐ Service에게 맡기기 (트랜잭션 안에서 처리됨)
        chatService.markRoomAsRead(meId, roomId);
    }


    /**
     * 특정 채팅방 메시지 목록 조회
     * GET /api/chat/rooms/{roomId}/messages
     */
    @GetMapping("/rooms/{roomId}/messages")
    public List<ChatMessageResponse> getMessages(
            @PathVariable Long roomId,
            Authentication authentication
    ) {

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

    // (프론트 백업용으로 남겨도 됨)
    @DeleteMapping("/{roomId}/leave")
    public ResponseEntity<Void> leave(
            @PathVariable Long roomId,
            Authentication authentication
    ) {
        Long userId = currentUserId(authentication);
        chatService.leaveRoom(roomId, userId);
        return ResponseEntity.noContent().build();
    }

    // ====== 공통 헬퍼 ======

    private Long currentUserId(Authentication authentication) {
        if (authentication == null) {
            throw new IllegalStateException("인증 정보가 없습니다.");
        }

        String name = authentication.getName();

        var byUsername = userRepository.findByUsername(name);
        if (byUsername.isPresent()) {
            return byUsername.get().getId();
        }

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
