package kr.ac.inhatc.paldari.auth.service;

import jakarta.transaction.Transactional;
import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.entity.VerificationToken;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.auth.repository.VerificationTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.*;

@Service
@RequiredArgsConstructor
public class UserService implements UserDetailsService {

    private final UserRepository userRepository;
    private final VerificationTokenRepository tokenRepository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final MailService mailService;

    // ================= UserDetailsService =================

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User u = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

        return new org.springframework.security.core.userdetails.User(
                u.getUsername(),
                u.getPassword() == null ? "" : u.getPassword(),
                u.isEnabled(),
                true,
                true,
                true,
                List.of(new SimpleGrantedAuthority(u.getRole()))
        );
    }

    @Transactional
    public void deleteByUsername(String username) {
        userRepository.deleteByUsername(username);
    }


    // ================= 회원가입 / 이메일 인증 =================

    @Transactional
    public void registerLocalUser(
            String username,
            String email,
            String rawPassword,
            String gender,         // 선택: "MALE", "FEMALE", "OTHER" 등
            String birthdate,      // 선택: "yyyy-MM-dd"
            List<String> countries // 선택: 국가 코드 리스트 (예: ["KR", "MY"])
    ) {
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
                false,
                "ROLE_USER",
                LocalDateTime.now()
        );

        // ✅ 성별 세팅 (null/공백이면 무시)
        if (gender != null && !gender.trim().isEmpty()) {
            user.setGender(gender.trim());
        }

        // ✅ 생년월일 세팅 ("yyyy-MM-dd" 형식)
        if (birthdate != null && !birthdate.trim().isEmpty()) {
            try {
                user.setBirthdate(LocalDate.parse(birthdate.trim()));
            } catch (DateTimeParseException e) {
                throw new IllegalArgumentException("Invalid birthdate format (expected yyyy-MM-dd): " + birthdate);
            }
        }

        // ✅ 국적 리스트 세팅 (null/공백 제거 후, 중복 제거)
        if (countries != null) {
            List<String> norm = countries.stream()
                    .filter(Objects::nonNull)
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .distinct()
                    .toList();
            user.getCountries().clear();
            user.getCountries().addAll(norm);
        }

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

    // ================= 프로필 / 조회 =================

    public User getByUsername(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
    }

    public User findByEmail(String email) {
        return userRepository.findByEmail(email).orElse(null);
    }

    public User findByUsernameAndEmail(String username, String email) {
        return userRepository.findByUsernameAndEmail(username, email).orElse(null);
    }

    // AuthController 등에서 쓸 수 있게 래핑
    @Transactional
    public User save(User user) {
        return userRepository.save(user);
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
