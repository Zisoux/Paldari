package kr.ac.inhatc.paldari.chats.repository;

import kr.ac.inhatc.paldari.chats.entity.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    List<ChatMessage> findByRoomIdOrderBySentAtAsc(Long roomId);

    @Query("""
        select max(m.id)
        from ChatMessage m
        where m.room.id = :roomId
    """)
    Long findLastMessageIdByRoomId(@Param("roomId") Long roomId);

    // ✅ "상대방이 보낸 TALK 메시지"만 카운트
    @Query("""
        select count(m)
        from ChatMessage m
        where m.room.id = :roomId
          and m.id > :lastReadMessageId
          and m.type = :type
          and m.sender <> :myName
    """)
    long countUnreadForUser(
            @Param("roomId") Long roomId,
            @Param("lastReadMessageId") Long lastReadMessageId,
            @Param("myName") String myName,
            @Param("type") ChatMessage.MessageType type   // ⭐ 여기!
    );
}
