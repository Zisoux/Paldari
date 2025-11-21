package kr.ac.inhatc.paldari.auth.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "users", indexes = {
        @Index(name = "idx_users_username", columnList = "username", unique = true),
        @Index(name = "idx_users_email", columnList = "email", unique = true)
})
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String username;  // 아이디

    @Column(nullable = false, unique = true)
    private String email;     // 이메일

    private String password;  // 암호화된 비밀번호

    @Column(nullable = false)
    private String provider = "LOCAL";  // LOCAL or GOOGLE

    @Column(nullable = false)
    private boolean enabled;  // 이메일 인증 여부

    private String gender;
    private LocalDate birthdate;

    // ✅ 국적 다중 선택: String country → List<String> countries
    @ElementCollection
    @CollectionTable(name = "user_countries", joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "country_code")
    private List<String> countries = new ArrayList<>();

    private String livingIn;
    private String language;
    private String introduction;

    @Column(nullable = false)
    private String role = "ROLE_USER";

    @CreatedDate
    private LocalDateTime created;

    // 🔹 Refresh Token 컬럼 추가
    @Column(name = "refresh_token")
    private String refreshToken;

    @Column(name = "refresh_token_expiry")
    private LocalDateTime refreshTokenExpiry;

    public User(String username, String email, String password,
                String provider, boolean enabled, String role, LocalDateTime created) {
        this.username = username;
        this.email = email;
        this.password = password;
        this.provider = provider;
        this.enabled = enabled;
        this.role = role;
        this.created = created;
    }

    public User(String username, String email, String password,
                String provider, boolean enabled) {
        this.username = username;
        this.email = email;
        this.password = password;
        this.provider = provider;
        this.enabled = enabled;
        this.role = "ROLE_USER";
        this.created = LocalDateTime.now();
    }

    // 🔹 유저의 지역 태그들 (#서울, #말레이시아 ...)
    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY, cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<UserRegion> regions = new HashSet<>();

    // 🔹 유저의 관심/도움 태그들 (#생활, #학업 ...)
    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY, cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<UserTag> tags = new HashSet<>();

    // 🔹 유저 설정 (알람, 매칭 허용, 실시간 번역)
    @OneToOne(mappedBy = "user", fetch = FetchType.LAZY)
    private UserSettings settings;
}
