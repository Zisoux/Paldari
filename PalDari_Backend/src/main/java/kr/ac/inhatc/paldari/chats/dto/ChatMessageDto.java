package kr.ac.inhatc.paldari.chats.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ChatMessageDto {

    public enum MessageType {
        ENTER, TALK, LEAVE
    }

    private MessageType type;
    private String roomId;
    private String sender;
    private String content;
    private String sentAt; // 필요하면 LocalDateTime으로
}
