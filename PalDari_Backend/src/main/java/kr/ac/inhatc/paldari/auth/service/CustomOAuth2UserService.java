package kr.ac.inhatc.paldari.auth.service;

import jakarta.transaction.Transactional;
import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.user.DefaultOAuth2User;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class CustomOAuth2UserService extends DefaultOAuth2UserService {

    private final UserRepository userRepository;

    @Override
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2User oAuth2User = super.loadUser(userRequest);

        var attr = oAuth2User.getAttributes();
        String email = (String) attr.get("email");
        String sub = (String) attr.get("sub");
        String username = (email != null) ? email : "google_" + sub;

        // DB에 없으면 새로 생성
        User user = userRepository.findByUsername(username).orElseGet(() -> {
            User nu = new User(
                    username,
                    (email != null) ? email : username, // 소셜로그인은 email이 username
                    null,             // 소셜 로그인은 비밀번호 없음
                    "GOOGLE",
                    true,             // 소셜 계정 즉시 활성화
                    "ROLE_USER",
                    LocalDateTime.now()
            );
            System.out.println("Saving new social user: " + username);
            return userRepository.save(nu);
        });

        // 활성화 여부 체크
        if (!user.isEnabled()) {
            user.setEnabled(true);
            userRepository.save(user);
        }

        var authorities = List.of(new SimpleGrantedAuthority(user.getRole()));
        return new DefaultOAuth2User(authorities, attr, "sub");
    }
}
