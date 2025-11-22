package kr.ac.inhatc.paldari.auth.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Getter
@Setter
@Table(name = "user_settings")
public class UserSettings {

    // 🔹 PK = user_id (users.id와 공유하는 키)
    @Id
    @Column(name = "user_id")
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "user_id", unique = true)
    private User user;

    @Column(name = "allow_notification", nullable = false)
    private boolean allowNotification = true;

    @Column(name = "allow_matching", nullable = false)
    private boolean allowMatching = true;

    @Column(name = "realtime_translation", nullable = false)
    private boolean realtimeTranslation = false;
}
