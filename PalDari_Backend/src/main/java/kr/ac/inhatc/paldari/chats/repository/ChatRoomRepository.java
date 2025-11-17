package kr.ac.inhatc.paldari.chats.repository;

import kr.ac.inhatc.paldari.chats.entity.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {
    Optional<ChatRoom> findByName(String name);

    @Query("""
        select r from ChatRoom r
        where r.id in (
            select m1.room.id from ChatRoomMember m1
            join ChatRoomMember m2 on m1.room = m2.room
            where m1.user.id = :userId1
              and m2.user.id = :userId2
        )
    """)
    Optional<ChatRoom> findPrivateRoomBetween(@Param("userId1") Long userId1,
                                              @Param("userId2") Long userId2);
}
