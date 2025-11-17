package kr.ac.inhatc.paldari.chats.repository;

import kr.ac.inhatc.paldari.chats.entity.ChatRoom;
import kr.ac.inhatc.paldari.chats.entity.ChatRoomMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ChatRoomMemberRepository extends JpaRepository<ChatRoomMember, Long> {
    // 두 유저 사이의 1:1 채팅방이 이미 있는지 찾고 싶으면
    @Query("""
        select m.room 
        from ChatRoomMember m 
        join ChatRoomMember m2 on m.room = m2.room
        where m.user.id = :userId1 and m2.user.id = :userId2
        """)
    Optional<ChatRoom> findDirectRoomBetweenUsers(Long userId1, Long userId2);

    @Query("""
        select crm.room
        from ChatRoomMember crm
        where crm.user.id = :userId
    """)
    List<ChatRoom> findRoomsByUserId(@Param("userId") Long userId);
}
