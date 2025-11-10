package kr.ac.inhatc.paldari.chats.controller;

import kr.ac.inhatc.paldari.chats.dto.ChatMessageDto;
import kr.ac.inhatc.paldari.chats.entity.ChatMessage;
import kr.ac.inhatc.paldari.chats.entity.ChatRoom;
import kr.ac.inhatc.paldari.chats.repository.ChatMessageRepository;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.time.LocalDateTime;

@Controller
@RequiredArgsConstructor
public class ChatStompController {

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatRoomRepository chatRoomRepository;
    private final ChatMessageRepository chatMessageRepository;

    /**
     * 클라이언트:
     * _stompClient.send("/app/chat.send/{roomId}", body: {...})
     */
    @MessageMapping("/chat.send/{roomId}")
    public void sendMessage(@DestinationVariable Long roomId,
                            @Payload ChatMessageDto dto,
                            Principal principal) {

        String username = principal.getName();

        ChatRoom room = chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("ChatRoom not found: " + roomId));

        ChatMessage saved = chatMessageRepository.save(
                ChatMessage.builder()
                        .room(room)
                        .type(ChatMessage.MessageType.TALK)
                        .sender(username)
                        .content(dto.getContent())
                        .sentAt(LocalDateTime.now())
                        .build()
        );

        dto.setRoomId(roomId.toString());
        dto.setSender(username);
        dto.setType(ChatMessageDto.MessageType.TALK);
        dto.setSentAt(saved.getSentAt().toString());

        // Flutter 구독 경로: /topic/chatroom.{roomId}
        messagingTemplate.convertAndSend("/topic/chatroom." + roomId, dto);
    }

    /**
     * 클라이언트:
     * _stompClient.send("/app/chat.enter/{roomId}", body: {...})
     */
    @MessageMapping("/chat.enter/{roomId}")
    public void enter(@DestinationVariable Long roomId,
                      @Payload ChatMessageDto dto,
                      Principal principal) {

        String username = principal.getName();

        ChatRoom room = chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("ChatRoom not found: " + roomId));

        ChatMessage saved = chatMessageRepository.save(
                ChatMessage.builder()
                        .room(room)
                        .type(ChatMessage.MessageType.ENTER)
                        .sender(username)
                        .content(username + " joined the room.")
                        .sentAt(LocalDateTime.now())
                        .build()
        );

        dto.setRoomId(roomId.toString());
        dto.setSender(username);
        dto.setType(ChatMessageDto.MessageType.ENTER);
        dto.setContent(saved.getContent());
        dto.setSentAt(saved.getSentAt().toString());

        messagingTemplate.convertAndSend("/topic/chatroom." + roomId, dto);
    }
}
