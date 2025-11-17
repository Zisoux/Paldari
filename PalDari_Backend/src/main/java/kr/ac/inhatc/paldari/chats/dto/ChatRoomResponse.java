package kr.ac.inhatc.paldari.chats.dto;

import kr.ac.inhatc.paldari.chats.entity.ChatRoom;
import lombok.Builder;

@Builder
public record ChatRoomResponse(
        Long roomId,
        String name,
        String subText
) {
    public static ChatRoomResponse from(ChatRoom room) {
        return ChatRoomResponse.builder()
                .roomId(room.getId())
                .name(room.getName())
                .subText(room.getSubText())
                .build();
    }
}
