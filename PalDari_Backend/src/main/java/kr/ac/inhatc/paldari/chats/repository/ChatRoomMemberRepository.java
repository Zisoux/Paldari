package kr.ac.inhatc.paldari.chats.repository;

import kr.ac.inhatc.paldari.auth.entity.User;
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
    Optional<ChatRoom> findDirectRoomBetweenUsers(
            @Param("userId1") Long userId1,
            @Param("userId2") Long userId2
    );

    // 특정 유저가 속한 모든 채팅방 조회
    @Query("""
        select crm.room
        from ChatRoomMember crm
        where crm.user.id = :userId
        """)
    List<ChatRoom> findRoomsByUserId(@Param("userId") Long userId);

    // 특정 방에서, meId가 아닌 "상대 유저" 찾기
    @Query("""
        select m2.user
        from ChatRoomMember m1
            join ChatRoomMember m2 on m1.room = m2.room
        where m1.room.id = :roomId
          and m1.user.id = :meId
          and m2.user.id <> :meId
        """)
    User findPartnerUser(
            @Param("roomId") Long roomId,
            @Param("meId") Long meId
    );

    // ⭐⭐ 추가: 특정 방(roomId) + 특정 유저(userId)에 해당하는 멤버 한 명 찾기
    @Query("""
        select m
        from ChatRoomMember m
        where m.room.id = :roomId
          and m.user.id = :userId
        """)
    Optional<ChatRoomMember> findByRoomIdAndUserId(
            @Param("roomId") Long roomId,
            @Param("userId") Long userId
    );
}
