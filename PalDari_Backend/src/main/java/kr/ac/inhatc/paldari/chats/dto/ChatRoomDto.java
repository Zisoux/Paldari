package kr.ac.inhatc.paldari.chats.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ChatRoomDto {
    private Long roomId;
    private String name;
    private String subText;
    private int unreadCount;
}
