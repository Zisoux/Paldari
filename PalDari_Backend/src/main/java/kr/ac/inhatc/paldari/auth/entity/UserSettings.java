package kr.ac.inhatc.paldari.auth.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Getter
@Setter
@Table(name = "user_settings")
public class UserSettings {

    @Id
    private Long id;  // users.id

    @OneToOne
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    private boolean allowNotification = true;
    private boolean allowMatching = true;
    private boolean realtimeTranslation = false;
}

