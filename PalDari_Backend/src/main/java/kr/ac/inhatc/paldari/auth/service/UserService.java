package kr.ac.inhatc.paldari.auth.service;

import jakarta.transaction.Transactional;
import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.entity.VerificationToken;
import kr.ac.inhatc.paldari.auth.jwt.JwtTokenProvider;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.auth.repository.VerificationTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
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

    // ================= UserDetailsService 구현 =================

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // username 기준으로 DB 조회 (LOCAL/GOOGLE 공통)
        User u = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

        return new org.springframework.security.core.userdetails.User(
                u.getUsername(),
                // 소셜 로그인 유저는 password null일 수 있으므로 빈 문자열 처리
                u.getPassword() == null ? "" : u.getPassword(),
                u.isEnabled(), // enabled
                true,          // accountNonExpired
                true,          // credentialsNonExpired
                true,          // accountNonLocked
                List.of(new SimpleGrantedAuthority(u.getRole()))
        );
    }

    // ================= 회원가입 / 이메일 인증 =================

    @Transactional
    public void registerLocalUser(String username, String email, String rawPassword) {
        if (userRepository.existsByUsername(username)) {
            throw new IllegalArgumentException("Username already exists");
        }
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already exists");
        }

        User user = new User(
                username,
                email,
                passwordEncoder.encode(rawPassword),
                "LOCAL",
                false,                 // 이메일 인증 전
                "ROLE_USER",
                LocalDateTime.now()
        );
        userRepository.save(user);

        String token = generateToken();
        VerificationToken vt = new VerificationToken(
                token,
                user,
                LocalDateTime.now().plusHours(24)
        );
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

    // ================= 로그인 + JWT 발급 =================

    /**
     * AuthenticationManager 없이 직접 인증 후 JWT 발급
     */
    public String loginAndIssueToken(String username, String rawPassword) {
        User u = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        // 로컬 계정만 패스워드 로그인
        if (u.getPassword() == null || !passwordEncoder.matches(rawPassword, u.getPassword())) {
            throw new BadCredentialsException("Bad credentials");
        }
        if (!u.isEnabled()) {
            throw new IllegalStateException("Email not verified");
        }

        return jwtTokenProvider.generateToken(u.getUsername());
    }

    // ================= 프로필 조회 =================

    /**
     * /api/auth/me 에서 사용할 사용자 프로필 맵
     */
    public Map<String, Object> getProfile(String username) {
        User u = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", u.getId());
        map.put("username", u.getUsername());
        map.put("email", u.getEmail());
        map.put("provider", u.getProvider());
        map.put("enabled", u.isEnabled());
        map.put("role", u.getRole());
        map.put("created", u.getCreated());
        return map;
    }

    /**
     * /api/auth/me 등에서 도메인 User 자체가 필요할 때 사용
     */
    public User getByUsername(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
    }

    // ================= 기타 유틸/검색 =================

    public User findByEmail(String email) {
        return userRepository.findByEmail(email).orElse(null);
    }

    public User findByUsernameAndEmail(String username, String email) {
        return userRepository.findByUsernameAndEmail(username, email).orElse(null);
    }

    @Transactional
    public void updatePasswordByUsernameAndEmail(String username, String email, String encodedPassword) {
        User user = userRepository.findByUsernameAndEmail(username, email)
                .orElseThrow(() -> new IllegalArgumentException("사용자 정보를 찾을 수 없습니다."));
        user.setPassword(encodedPassword);
        userRepository.save(user);
    }

    @Transactional
    public void updatePasswordRaw(String username, String email, String rawPassword) {
        User user = userRepository.findByUsernameAndEmail(username, email)
                .orElseThrow(() -> new IllegalArgumentException("사용자 정보를 찾을 수 없습니다."));
        user.setPassword(passwordEncoder.encode(rawPassword));
        userRepository.save(user);
    }

    // ================= 내부 토큰 생성 유틸 =================

    private String generateToken() {
        byte[] bytes = new byte[24];
        new SecureRandom().nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
