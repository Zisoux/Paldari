package kr.ac.inhatc.paldari.auth.service;

import jakarta.transaction.Transactional;
import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.client.oidc.userinfo.OidcUserRequest;
import org.springframework.security.oauth2.client.oidc.userinfo.OidcUserService;
import org.springframework.security.oauth2.core.oidc.user.DefaultOidcUser;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class CustomOidcUserService extends OidcUserService {

    private final UserRepository userRepository;

    @Override
    public OidcUser loadUser(OidcUserRequest userRequest) {
        // 기본 OidcUser 먼저 가져오기
        OidcUser oidcUser = super.loadUser(userRequest);

        var attr = oidcUser.getAttributes();
        log.info("[OIDC] attributes={}", attr);

        // 1️⃣ email 추출 (각 단계별로 한 번씩만 대입)
        String emailFromAttr = null;
        Object emailAttr = attr.get("email");
        if (emailAttr instanceof String) {
            emailFromAttr = (String) emailAttr;
        }

        String emailFromUserInfo = null;
        if (oidcUser.getUserInfo() != null) {
            emailFromUserInfo = oidcUser.getUserInfo().getEmail();
        }

        String email = (emailFromAttr != null) ? emailFromAttr : emailFromUserInfo;

        if (email == null) {
            throw new IllegalStateException("Google email not found in OIDC response");
        }

        // 🔒 lambda에서 쓸 final 변수
        final String finalEmail = email;

        // 2️⃣ email 기준으로 유저 조회 or 생성
        User user = userRepository.findByEmail(finalEmail)
                .orElseGet(() -> {
                    // User(String username, String email, String password,
                    //      String provider, boolean enabled, String role, LocalDateTime created)
                    User nu = new User(
                            finalEmail,          // username = email
                            finalEmail,          // email
                            null,                // password (소셜 로그인: null)
                            "GOOGLE",            // provider
                            true,                // enabled
                            "ROLE_USER",         // role
                            LocalDateTime.now()  // created
                    );
                    log.info("[OIDC] Saving new social user: {}", finalEmail);
                    return userRepository.save(nu);
                });

        // 3️⃣ 비활성 상태였다면 활성화
        if (!user.isEnabled()) {
            user.setEnabled(true);
            userRepository.save(user);
            log.info("[OIDC] Re-enabled user: {}", finalEmail);
        }

        // 4️⃣ 권한 & Principal 구성
        var authorities = List.of(new SimpleGrantedAuthority(user.getRole()));

        return new DefaultOidcUser(
                authorities,
                oidcUser.getIdToken(),
                oidcUser.getUserInfo(),
                "email" // SecurityContext.getAuthentication().getName() == finalEmail
        );
    }
}
