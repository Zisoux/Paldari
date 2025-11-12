package kr.ac.inhatc.paldari.auth.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

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
    @OnDelete(action = OnDeleteAction.CASCADE)
    private User user;

    private boolean allowNotification = true;
    private boolean allowMatching = true;
    private boolean realtimeTranslation = false;
}

