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

    @Column(name = "living_in")
    private String livingIn;

    private String language;
    private String introduction;

    @Column(nullable = false)
    private String role = "ROLE_USER";

    @CreatedDate
    @Column(name = "created")
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

    public void setCountries(List<String> countries) {
        this.countries = countries.stream()
                .map(c -> c == null ? null : c.trim())
                .map(c -> switch (c) {

                    // 🇲🇾 말레이시아
                    case "말레이시아", "Malaysia", "MY", "my", "malaysia" -> "말레이시아";

                    // 🇰🇷 한국
                    case "한국", "대한민국", "Korea", "South Korea",
                         "KR", "kr", "kor", "korea" -> "한국";

                    // 🇯🇵 일본
                    case "일본", "Japan", "JP", "jp", "japan" -> "일본";

                    // 🇺🇸 미국
                    case "미국", "USA", "US", "United States",
                         "america", "usa", "us" -> "미국";

                    // 🇨🇦 캐나다
                    case "캐나다", "Canada", "CA", "ca", "canada" -> "캐나다";

                    // 🇦🇺 호주
                    case "호주", "Australia", "AU", "au", "australia" -> "호주";

                    // 🇬🇧 영국
                    case "영국", "United Kingdom", "UK", "GB",
                         "England", "uk", "gb", "england" -> "영국";

                    // 🇩🇪 독일
                    case "독일", "Germany", "DE", "de", "germany" -> "독일";

                    // 🇫🇷 프랑스
                    case "프랑스", "France", "FR", "fr", "france" -> "프랑스";

                    default -> c;
                })
                .toList();
    }


}

