package kr.ac.inhatc.paldari.auth.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.service.UserService;
import kr.ac.inhatc.paldari.auth.service.MailService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;
    private final PasswordEncoder passwordEncoder;
    private final MailService mailService;

    // === 비밀번호 재설정용 인메모리 저장 (운영은 Redis/DB 권장) ===
    private final ConcurrentHashMap<String, CodeEntry> codeStore = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, AttemptEntry> attemptStore = new ConcurrentHashMap<>();

    // 코드 만료/시도 제한 설정 (application.yml로 조절)
    private final Duration codeTtl;
    private final int maxAttempts;

    public AuthController(
            UserService userService,
            PasswordEncoder passwordEncoder,
            MailService mailService,
            @Value("${pwreset.code-ttl-minutes:10}") long codeTtlMinutes,
            @Value("${pwreset.max-attempts:5}") int maxAttempts
    ) {
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
        this.mailService = mailService;
        this.codeTtl = Duration.ofMinutes(codeTtlMinutes);
        this.maxAttempts = maxAttempts;
    }

    // ---- DTOs ----
    public static record SignUpRequest(
            @NotBlank String username,
            @Email String email,
            @NotBlank String password
    ) {}

    public static record LoginRequest(
            @NotBlank String username,
            @NotBlank String password
    ) {}

    // ---- Endpoints ----

    /** 회원가입: 비활성으로 저장 후 인증메일 발송 */
    @PostMapping("/signup")
    public ResponseEntity<?> signup(@Valid @RequestBody SignUpRequest req) {
        userService.registerLocalUser(req.username(), req.email(), req.password());
        return ResponseEntity.ok(Map.of("message", "Sign-up success. Please verify your email."));
    }

    /** 이메일 인증 링크 검증 (JSON 그대로 유지) */
    @GetMapping("/verify")
    public ResponseEntity<?> verify(@RequestParam("token") String token) {
        boolean ok = userService.verifyEmailToken(token);
        if (ok) return ResponseEntity.ok(Map.of("message", "Email verified. You can login now."));
        return ResponseEntity.badRequest().body(Map.of("message", "Invalid or expired token."));
    }

    /** 일반 로그인: 성공 시 JWT 반환 */
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest req) {
        try {
            String jwt = userService.loginAndIssueToken(req.username(), req.password());
            return ResponseEntity.ok(Map.of("token", jwt));
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(401).body(Map.of("message", "아이디 또는 비밀번호가 올바르지 않습니다."));
        } catch (IllegalStateException e) { // 이메일 미인증 등
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        }
    }

    // 아이디 찾기: 이메일 존재 여부 확인
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

        // 아이디 그대로 반환 (마스킹 X)
        String username = user.getUsername();
        return ResponseEntity.ok(Map.of(
                "exists", true,
                "username", username,
                "message", "가입된 이메일입니다. (아이디: " + username + " )"
        ));
    }


    /* ===================================================================================
     * 비밀번호 재설정: 2단계(코드만) 버전
     *  1) 코드 요청:  POST /api/auth/pw-reset/request {username, email}
     *  2) 변경 확정:  POST /api/auth/pw-reset/confirm {username, email, code, newPassword}
     * =================================================================================== */

    /** 1) 비밀번호 재설정: 코드 요청 */
    @PostMapping(path = "/pw-reset/request",
            consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> pwResetRequest(@RequestBody Map<String, String> body) {
        String username = body.getOrDefault("username", "").trim();
        String email    = body.getOrDefault("email", "").trim();

        if (username.isEmpty() || email.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "username과 email은 필수입니다."));
        }

        // 사용자 매칭 확인
        User user = userService.findByUsernameAndEmail(username, email);
        if (user == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "사용자 정보가 일치하지 않습니다."));
        }

        // 6자리 코드 생성 & 저장 (만료 + 일회성)
        String code = String.format("%06d", (int)(Math.random() * 1_000_000));
        String key  = key(username, email);
        codeStore.put(key, new CodeEntry(code, Instant.now().plus(codeTtl), false));
        attemptStore.put(key, new AttemptEntry(0));

        // 이메일 발송 (MailService 사용) — HTML/텍스트 둘 다 전송
        mailService.sendPasswordResetCode(email, code, (int) codeTtl.toMinutes());

        return ResponseEntity.ok(Map.of("ok", true));
    }

    /** 2) 비밀번호 재설정: 코드 + 새비번으로 즉시 변경 */
    @PostMapping(path = "/pw-reset/confirm",
            consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> pwResetConfirm(@RequestBody Map<String, String> body) {
        String username   = body.getOrDefault("username", "").trim();
        String email      = body.getOrDefault("email", "").trim();
        String code       = body.getOrDefault("code", "").trim();
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

        // 시도 제한
        AttemptEntry attempts = attemptStore.computeIfAbsent(key, k -> new AttemptEntry(0));
        if (attempts.count >= maxAttempts) {
            codeStore.remove(key);
            attemptStore.remove(key);
            return ResponseEntity.badRequest().body(Map.of("message", "시도 횟수를 초과했습니다. 코드를 다시 요청해 주세요."));
        }

        // 만료/사용 여부 체크
        if (Instant.now().isAfter(entry.expiresAt)) {
            codeStore.remove(key);
            attemptStore.remove(key);
            return ResponseEntity.badRequest().body(Map.of("message", "인증 코드가 만료되었습니다."));
        }
        if (entry.used) {
            return ResponseEntity.badRequest().body(Map.of("message", "이미 사용된 인증 코드입니다."));
        }

        // 코드 비교
        if (!Objects.equals(entry.code, code)) {
            attempts.count++;
            return ResponseEntity.badRequest().body(Map.of("message", "인증 코드가 올바르지 않습니다."));
        }

        // 일회성 처리
        entry.used = true;
        codeStore.remove(key);
        attemptStore.remove(key);

        // 비밀번호 변경
        String encoded = passwordEncoder.encode(newPwPlain);
        userService.updatePasswordByUsernameAndEmail(username, email, encoded);

        return ResponseEntity.ok(Map.of("ok", true));
    }

    /** 내 프로필 조회: JWT 필터가 넣어준 request attribute 사용 */
    @GetMapping("/me")
    public ResponseEntity<?> me(Principal principal) {
        if (principal == null) {
            return ResponseEntity.status(401)
                    .body(Map.of("message", "UNAUTHORIZED"));
        }

        String username = principal.getName();

        var user = userService.getByUsername(username); // ⭐ 여기!

        return ResponseEntity.ok(Map.of(
                "username", user.getUsername(),
                "email", user.getEmail(),
                "role", user.getRole()
        ));
    }



    /* ================== 내부 유틸 ================== */

    private String key(String username, String email) {
        return username + "|" + email.toLowerCase();
    }

    private static final class CodeEntry {
        final String code;
        final Instant expiresAt;
        volatile boolean used;
        CodeEntry(String code, Instant expiresAt, boolean used) {
            this.code = code; this.expiresAt = expiresAt; this.used = used;
        }
    }
    private static final class AttemptEntry {
        int count;
        AttemptEntry(int c) { this.count = c; }
    }
}
