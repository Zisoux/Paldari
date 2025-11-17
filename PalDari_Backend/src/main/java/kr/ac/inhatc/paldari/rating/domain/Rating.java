package kr.ac.inhatc.paldari.rating.domain;

import jakarta.persistence.*;
import kr.ac.inhatc.paldari.auth.entity.User;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "ratings")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class Rating {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 평가한 사람(로그인한 유저)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "rater_id", nullable = false)
    private User rater;

    /**
     * 평가 받은 사람(Buddy, 마이페이지 주인)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "buddy_id", nullable = false)
    private User buddy;

    /**
     * 어떤 채팅방/매칭에 대한 평가인지 구분하기 위한 id
     * 실제 ChatRoom 엔티티와 연관 관계 안 맺고, 일단 숫자 컬럼만 사용
     */
    @Column(name = "chat_room_id")
    private Long chatRoomId;

    /**
     * 평점 (1 ~ 5)
     */
    @Column(nullable = false)
    private int score;

    /**
     * 선택 사항 코멘트
     */
    @Column(length = 1000)
    private String comment;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * 점수 / 코멘트 수정용 도메인 메서드
     */
    public void update(int score, String comment) {
        this.score = score;
        this.comment = comment;
    }
}
