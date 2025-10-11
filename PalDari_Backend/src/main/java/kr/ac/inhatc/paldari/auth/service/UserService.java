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

    @Override
    public UserDetails loadUserByUsername(String username) {
        return userRepository.findByUsername(username)
                .map(u -> new org.springframework.security.core.userdetails.User(
                        u.getUsername(),
                        u.getPassword() == null ? "" : u.getPassword(),
                        u.isEnabled(), true, true, true,
                        List.of(new SimpleGrantedAuthority(u.getRole()))
                ))
                .orElseGet(() -> {
                    // DB에 없으면 소셜 계정으로 새로 생성
                    User newUser = new User(
                            username,
                            username, // 소셜로그인은 email이 username
                            null,
                            "GOOGLE",
                            true,
                            "ROLE_USER",
                            LocalDateTime.now()
                    );
                    userRepository.save(newUser);
                    return new org.springframework.security.core.userdetails.User(
                            newUser.getUsername(),
                            "",
                            true, true, true, true,
                            List.of(new SimpleGrantedAuthority(newUser.getRole()))
                    );
                });
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
