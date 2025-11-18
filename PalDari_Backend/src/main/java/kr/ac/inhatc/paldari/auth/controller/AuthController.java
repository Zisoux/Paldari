package kr.ac.inhatc.paldari.auth.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.jwt.JwtTokenProvider;
import kr.ac.inhatc.paldari.auth.service.MailService;
import kr.ac.inhatc.paldari.auth.service.UserService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;
    private final PasswordEncoder passwordEncoder;
    private final MailService mailService;
    private final JwtTokenProvider jwtTokenProvider;

    // 비밀번호 재설정용 인메모리 저장
    private final ConcurrentHashMap<String, CodeEntry> codeStore = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, AttemptEntry> attemptStore = new ConcurrentHashMap<>();

    private final Duration codeTtl;
    private final int maxAttempts;

    public AuthController(
            UserService userService,
            PasswordEncoder passwordEncoder,
            MailService mailService,
            JwtTokenProvider jwtTokenProvider,
            @Value("${pwreset.code-ttl-minutes:10}") long codeTtlMinutes,
            @Value("${pwreset.max-attempts:5}") int maxAttempts
    ) {
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
        this.mailService = mailService;
        this.jwtTokenProvider = jwtTokenProvider;
        this.codeTtl = Duration.ofMinutes(codeTtlMinutes);
        this.maxAttempts = maxAttempts;
    }

    // ==== DTOs ====

    public static record SignUpRequest(
            @NotBlank String username,
            @Email String email,
            @NotBlank String password,
            String gender,          // 선택: "MALE", "FEMALE", "OTHER" 등
            String birthdate        // 선택: "yyyy-MM-dd"
    ) {}

    public static record LoginRequest(
            @NotBlank String username,
            @NotBlank String password
    ) {}

    // ================= 회원가입 / 이메일 인증 =================

    @PostMapping("/signup")
    public ResponseEntity<?> signup(@Valid @RequestBody SignUpRequest req) {

        // gender, birthdate까지 같이 전달
        userService.registerLocalUser(
                req.username(),
                req.email(),
                req.password(),
                req.gender(),
                req.birthdate()
        );

        return ResponseEntity.ok(
                Map.of("message", "Sign-up success. Please verify your email.")
        );
    }

    @GetMapping("/verify")
    public ResponseEntity<?> verify(@RequestParam("token") String token) {
        boolean ok = userService.verifyEmailToken(token);
        if (ok) {
            return ResponseEntity.ok(Map.of("message", "Email verified. You can login now."));
        }
        return ResponseEntity.badRequest().body(Map.of("message", "Invalid or expired token."));
    }

    // ================= 로그인 (Access + Refresh 발급) =================

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest req) {
        try {
            User user;

            String input = req.username().trim();

            // 이메일 형식인지 검사
            if (input.contains("@")) {
                user = userService.findByEmail(input);
            } else {
                user = userService.getByUsername(input);
            }

            if (user == null) {
                throw new BadCredentialsException("bad credentials");
            }

            if (user.getPassword() == null ||
                    !passwordEncoder.matches(req.password(), user.getPassword())) {
                throw new BadCredentialsException("bad credentials");
            }

            if (!user.isEnabled()) {
                throw new IllegalStateException("이메일 인증이 완료되지 않았습니다.");
            }

            String subject = user.getUsername(); // username으로 JWT subject 저장

            String accessToken = jwtTokenProvider.generateAccessToken(subject);
            String refreshToken = jwtTokenProvider.generateRefreshToken(subject);

            user.setRefreshToken(refreshToken);
            user.setRefreshTokenExpiry(LocalDateTime.now().plusDays(7));
            userService.save(user);

            return ResponseEntity.ok(Map.of(
                    "accessToken", accessToken,
                    "refreshToken", refreshToken
            ));

        } catch (BadCredentialsException e) {
            return ResponseEntity.status(401)
                    .body(Map.of("message", "아이디 또는 비밀번호가 올바르지 않습니다."));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(403)
                    .body(Map.of("message", e.getMessage()));
        }
    }

    // ================= 리프레시 토큰 재발급 =================

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@RequestBody Map<String, String> body) {
        String refreshToken = body.getOrDefault("refreshToken", "").trim();
        if (refreshToken.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "refreshToken is required"));
        }

        if (!jwtTokenProvider.validateToken(refreshToken)) {
            return ResponseEntity.status(401).body(Map.of("message", "Invalid refresh token"));
        }

        String type = jwtTokenProvider.getType(refreshToken);
        if (!"refresh".equals(type)) {
            return ResponseEntity.status(401).body(Map.of("message", "Not a refresh token"));
        }

        String subject = jwtTokenProvider.getSubject(refreshToken);
        User user = userService.getByUsername(subject);

        if (user.getRefreshToken() == null ||
                !user.getRefreshToken().equals(refreshToken)) {
            return ResponseEntity.status(401).body(Map.of("message", "Refresh token mismatch"));
        }

        if (user.getRefreshTokenExpiry() != null &&
                user.getRefreshTokenExpiry().isBefore(LocalDateTime.now())) {
            return ResponseEntity.status(401).body(Map.of("message", "Refresh token expired"));
        }

        String newAccess = jwtTokenProvider.generateAccessToken(subject);
        String newRefresh = jwtTokenProvider.generateRefreshToken(subject);

        user.setRefreshToken(newRefresh);
        user.setRefreshTokenExpiry(LocalDateTime.now().plusDays(7));
        userService.save(user);

        return ResponseEntity.ok(Map.of(
                "accessToken", newAccess,
                "refreshToken", newRefresh
        ));
    }

    // ================= 아이디 찾기 =================

    @PostMapping("/findEmail")
    public ResponseEntity<?> findEmail(@RequestBody Map<String, String> body) {
        String email = body.getOrDefault("email", "").trim();

        if (email.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "email은 필수입니다."));
        }

        User user = userService.findByEmail(email);
        if (user == null) {
            return ResponseEntity.ok(Map.of(
                    "exists", false,
                    "message", "등록되지 않은 이메일입니다."
            ));
        }

        String username = user.getUsername();
        return ResponseEntity.ok(Map.of(
                "exists", true,
                "username", username,
                "message", "가입된 이메일입니다. (아이디: " + username + " )"
        ));
    }

    // ================= 비밀번호 재설정 =================

    @PostMapping(
            path = "/pw-reset/request",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<?> pwResetRequest(@RequestBody Map<String, String> body) {
        String username = body.getOrDefault("username", "").trim();
        String email = body.getOrDefault("email", "").trim();

        if (username.isEmpty() || email.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "username과 email은 필수입니다."));
        }

        User user = userService.findByUsernameAndEmail(username, email);
        if (user == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "사용자 정보가 일치하지 않습니다."));
        }

        String code = String.format("%06d", (int) (Math.random() * 1_000_000));
        String key = key(username, email);
        codeStore.put(key, new CodeEntry(code, Instant.now().plus(codeTtl), false));
        attemptStore.put(key, new AttemptEntry(0));

        mailService.sendPasswordResetCode(email, code, (int) codeTtl.toMinutes());

        return ResponseEntity.ok(Map.of("ok", true));
    }

    @PostMapping(
            path = "/pw-reset/confirm",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<?> pwResetConfirm(@RequestBody Map<String, String> body) {
        String username = body.getOrDefault("username", "").trim();
        String email = body.getOrDefault("email", "").trim();
        String code = body.getOrDefault("code", "").trim();
        String newPwPlain = body.getOrDefault("newPassword", "").trim();

        if (username.isEmpty() || email.isEmpty() || code.isEmpty() || newPwPlain.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "username, email, code, newPassword는 필수입니다."));
        }
        if (newPwPlain.length() < 6) {
            return ResponseEntity.badRequest().body(Map.of("message", "비밀번호는 6자 이상이어야 합니다."));
        }

        String key = key(username, email);
        CodeEntry entry = codeStore.get(key);
        if (entry == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "인증 코드를 먼저 요청해 주세요."));
        }

        AttemptEntry attempts = attemptStore.computeIfAbsent(key, k -> new AttemptEntry(0));
        if (attempts.count >= maxAttempts) {
            codeStore.remove(key);
            attemptStore.remove(key);
            return ResponseEntity.badRequest().body(Map.of("message", "시도 횟수를 초과했습니다. 코드를 다시 요청해 주세요."));
        }

        if (Instant.now().isAfter(entry.expiresAt)) {
            codeStore.remove(key);
            attemptStore.remove(key);
            return ResponseEntity.badRequest().body(Map.of("message", "인증 코드가 만료되었습니다."));
        }
        if (entry.used) {
            return ResponseEntity.badRequest().body(Map.of("message", "이미 사용된 인증 코드입니다."));
        }

        if (!Objects.equals(entry.code, code)) {
            attempts.count++;
            return ResponseEntity.badRequest().body(Map.of("message", "인증 코드가 올바르지 않습니다."));
        }

        entry.used = true;
        codeStore.remove(key);
        attemptStore.remove(key);

        String encoded = passwordEncoder.encode(newPwPlain);
        userService.updatePasswordByUsernameAndEmail(username, email, encoded);

        return ResponseEntity.ok(Map.of("ok", true));
    }

    // ================= 내 프로필 =================

    @GetMapping("/me")
    public ResponseEntity<?> me(Principal principal) {
        if (principal == null) {
            return ResponseEntity.status(401)
                    .body(Map.of("message", "UNAUTHORIZED"));
        }

        String username = principal.getName();
        User user = userService.getByUsername(username);

        return ResponseEntity.ok(Map.of(
                "username", user.getUsername(),
                "email", user.getEmail(),
                "role", user.getRole(),
                "enabled", user.isEnabled()
        ));
    }

    // ================= 회원탈퇴 =================

    @DeleteMapping("/withdraw")
    public ResponseEntity<?> withdraw(Principal principal) {
        if (principal == null) {
            return ResponseEntity.status(401)
                    .body(Map.of("message", "UNAUTHORIZED"));
        }

        String username = principal.getName();
        userService.deleteByUsername(username);

        return ResponseEntity.ok(Map.of("message", "Account deleted"));
    }

    // ================= 내부 유틸 =================

    private String key(String username, String email) {
        return username + "|" + email.toLowerCase();
    }

    private static final class CodeEntry {
        final String code;
        final Instant expiresAt;
        volatile boolean used;
        CodeEntry(String code, Instant expiresAt, boolean used) {
            this.code = code;
            this.expiresAt = expiresAt;
            this.used = used;
        }
    }

    private static final class AttemptEntry {
        int count;
        AttemptEntry(int c) {
            this.count = c;
        }
    }
}
