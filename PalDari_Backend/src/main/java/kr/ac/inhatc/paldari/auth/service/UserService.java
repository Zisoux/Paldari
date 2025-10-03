package kr.ac.inhatc.paldari.auth.service;

import jakarta.transaction.Transactional;
import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.entity.VerificationToken;
import kr.ac.inhatc.paldari.auth.jwt.JwtTokenProvider;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.auth.repository.VerificationTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class UserService implements UserDetailsService {

    private final UserRepository userRepository;
    private final VerificationTokenRepository tokenRepository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final MailService mailService;
    private final JwtTokenProvider jwtTokenProvider;

    // 로그인용(UserDetailsService)
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User u = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        List<GrantedAuthority> auths = List.of(new SimpleGrantedAuthority(u.getRole()));
        return new org.springframework.security.core.userdetails.User(
                u.getUsername(),
                u.getPassword() == null ? "" : u.getPassword(),
                u.isEnabled(), true, true, true,
                auths
        );
    }

    @Transactional
    public void registerLocalUser(String username, String email, String rawPassword) {
        if (userRepository.existsByUsername(username)) {
            throw new IllegalArgumentException("Username already exists");
        }
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already exists");
        }

        // (username, email, password, provider, enabled, role, created)
        User user = new User(
                username,
                email,
                passwordEncoder.encode(rawPassword),
                "LOCAL",
                false,
                "ROLE_USER",
                LocalDateTime.now()
        );
        userRepository.save(user);

        String token = generateToken();
        VerificationToken vt = new VerificationToken(token, user, LocalDateTime.now().plusHours(24));
        tokenRepository.save(vt);

        mailService.sendVerificationEmail(email, token);
    }

    @Transactional
    public boolean verifyEmailToken(String token) {
        var vtOpt = tokenRepository.findByToken(token);
        if (vtOpt.isEmpty()) return false;

        var vt = vtOpt.get();
        if (vt.getExpiryDate().isBefore(LocalDateTime.now())) {
            tokenRepository.delete(vt);
            return false;
        }

        User u = vt.getUser();
        u.setEnabled(true);
        userRepository.save(u);
        tokenRepository.delete(vt);
        return true;
    }

    /** AuthenticationManager 없이 직접 비밀번호 검증 */
    public String loginAndIssueToken(String username, String rawPassword) {
        User u = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        // 로컬 계정만 비밀번호 로그인 가능 (소셜 전용 계정은 password가 null일 수 있음)
        if (u.getPassword() == null || !passwordEncoder.matches(rawPassword, u.getPassword())) {
            throw new BadCredentialsException("Bad credentials");
        }
        if (!u.isEnabled()) {
            throw new IllegalStateException("Email not verified");
        }
        return jwtTokenProvider.generateToken(u.getUsername());
    }

    /** (선택) 통합 OAuth2UserService로 옮겼다면 이 메서드는 삭제해도 됩니다. */
    public UserDetails handleOAuth2Success(org.springframework.security.oauth2.core.user.OAuth2User oauthUser) {
        String email = (String) oauthUser.getAttributes().getOrDefault("email", null);
        String username = email != null ? email : "user_" + UUID.randomUUID();

        User user = userRepository.findByUsername(username)
                .orElseGet(() -> {
                    User nu = new User(
                            username,
                            email != null ? email : (username + "@nomail.local"),
                            null,
                            "GOOGLE",
                            true,
                            "ROLE_USER",
                            LocalDateTime.now()
                    );
                    return userRepository.save(nu);
                });

        user.setEnabled(true);
        user.setProvider("GOOGLE");
        userRepository.save(user);

        List<GrantedAuthority> auths = List.of(new SimpleGrantedAuthority(user.getRole()));
        return new org.springframework.security.core.userdetails.User(
                user.getUsername(), "", true, true, true, true, auths
        );
    }

    public Map<String, Object> getProfile(String username) {
        User u = userRepository.findByUsername(username).orElseThrow();
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", u.getId());
        map.put("username", u.getUsername());
        map.put("email", u.getEmail());
        map.put("provider", u.getProvider());
        map.put("enabled", u.isEnabled());
        map.put("role", u.getRole());
        map.put("created", u.getCreated()); // 엔티티의 getter 이름에 맞춤
        return map;
    }

    private String generateToken() {
        byte[] bytes = new byte[24];
        new SecureRandom().nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
