package kr.ac.inhatc.paldari.chats.repository;

import kr.ac.inhatc.paldari.chats.entity.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {
}
