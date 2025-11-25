package kr.ac.inhatc.paldari.chats.dto;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.chats.entity.ChatRoom;
import kr.ac.inhatc.paldari.chats.entity.ChatRoomMember;
import lombok.Builder;

@Builder
public record ChatRoomResponse(
        Long roomId,
        String name,
        Long buddyUserId,
        String subText
) {

    /**
     * currentUserId 기준으로 "상대방(buddy)"의 userId 를 세팅하는 팩토리 메서드
     */
    public static ChatRoomResponse from(ChatRoom room, Long currentUserId) {

        // 나(currentUserId)가 아닌 멤버 = 상대방(buddy)
        User buddy = room.getMembers().stream()
                .map(ChatRoomMember::getUser)
                .filter(u -> !u.getId().equals(currentUserId))
                .findFirst()
                .orElse(null);

        Long buddyId = (buddy != null) ? buddy.getId() : null;

        return ChatRoomResponse.builder()
                .roomId(room.getId())
                .name(room.getName())
                .buddyUserId(buddyId)      // ⭐ 여기서 반드시 세팅
                .subText(room.getSubText())
                .build();
    }
}
