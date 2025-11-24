package kr.ac.inhatc.paldari.chats.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "chat_room")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatRoom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 표시용 이름 (상대방 닉네임, 매칭명 등)
    private String name;

    // 국가/설명 같은 서브 텍스트 (옵션)
    private String subText;

    private LocalDateTime createdAt;

    @PrePersist
    public void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }

    // ================================
    // 🔥 추가된 부분 (가장 중요)
    // ================================

    // 채팅방 멤버 (유저와의 연결)
    @OneToMany(
            mappedBy = "room",
            cascade = CascadeType.ALL,          // 방 삭제 → 멤버 자동 삭제
            orphanRemoval = true,               // 고아 객체 자동 삭제
            fetch = FetchType.LAZY
    )
    @Builder.Default
    private List<ChatRoomMember> members = new ArrayList<>();

    // 채팅 메시지들
    @OneToMany(
            mappedBy = "room",
            cascade = CascadeType.ALL,          // 방 삭제 → 메시지 자동 삭제
            orphanRemoval = true,
            fetch = FetchType.LAZY
    )
    @Builder.Default
    private List<ChatMessage> messages = new ArrayList<>();


    // 유틸 메서드
    public void addMember(ChatRoomMember member) {
        members.add(member);
        member.setRoom(this);
    }

    public void removeMember(ChatRoomMember member) {
        members.remove(member);
        member.setRoom(null);
    }

    public void addMessage(ChatMessage message) {
        messages.add(message);
        message.setRoom(this);
    }
}
