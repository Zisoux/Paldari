package kr.ac.inhatc.paldari.auth.service;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.jwt.JwtTokenProvider;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.*;
import org.springframework.security.oauth2.core.user.DefaultOAuth2User;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class OAuth2UserService
        implements org.springframework.security.oauth2.client.userinfo.OAuth2UserService<OAuth2UserRequest, OAuth2User>,
        AuthenticationSuccessHandler {

    private final UserRepository userRepository;
    private final JwtTokenProvider jwtTokenProvider;

    @Value("${app.oauth2.redirect:http://localhost:5173/oauth-success}")
    private String redirectBase;

    /** 사용자 정보 로드 + 우리 DB에 유저 생성/업데이트 */
    @Override
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        var delegate = new DefaultOAuth2UserService();
        OAuth2User oAuth2User = delegate.loadUser(userRequest);

        Map<String, Object> attr = oAuth2User.getAttributes();
        String email = (String) attr.get("email");
        String sub = (String) attr.get("sub");           // Google 고유 ID
        String username = (email != null) ? email : "google_" + sub;

        // find or create
        User user = userRepository.findByUsername(username).orElseGet(() -> {
            User nu = new User(
                    username,
                    (email != null) ? email : username + "@nomail.local",
                    null,                   // 소셜은 비번 없음
                    "GOOGLE",
                    true,                   // 소셜은 즉시 활성화
                    "ROLE_USER",
                    LocalDateTime.now()
            );
            return userRepository.save(nu);
        });

        if (!user.isEnabled()) { user.setEnabled(true); userRepository.save(user); }
        var authorities = List.of(new SimpleGrantedAuthority(user.getRole()));

        // user-name-attribute는 application.yml의 provider.google.user-name-attribute=sub 와 일치
        return new DefaultOAuth2User(authorities, attr, "sub");
    }

    /** 로그인 성공 시 JWT 발급 후 프론트로 리다이렉트 */
    @Override
    public void onAuthenticationSuccess(HttpServletRequest request,
                                        HttpServletResponse response,
                                        Authentication authentication) throws IOException {
        OAuth2User principal = (OAuth2User) authentication.getPrincipal();
        String email = (String) principal.getAttributes().get("email");
        String sub = (String) principal.getAttributes().get("sub");
        String username = (email != null) ? email : "google_" + sub;

        String token = jwtTokenProvider.generateToken(username);

        String base = redirectBase.endsWith("/")
                ? redirectBase.substring(0, redirectBase.length() - 1)
                : redirectBase;

        String redirectUrl = base + "?token=" + URLEncoder.encode(token, StandardCharsets.UTF_8);
        response.sendRedirect(redirectUrl);
    }
}
