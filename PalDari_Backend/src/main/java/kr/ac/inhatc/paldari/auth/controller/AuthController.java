package kr.ac.inhatc.paldari.auth.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import kr.ac.inhatc.paldari.auth.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;

    public AuthController(UserService userService) {
        this.userService = userService;
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

    /** 회원가입: 비활성로 저장 후 인증메일 발송 */
    @PostMapping("/signup")
    public ResponseEntity<?> signup(@Valid @RequestBody SignUpRequest req) {
        userService.registerLocalUser(req.username(), req.email(), req.password());
        return ResponseEntity.ok(Map.of("message", "Sign-up success. Please verify your email."));
    }

    /** 이메일 인증 링크 검증 */
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
            return ResponseEntity.status(401).body(Map.of("message", "Invalid credentials"));
        } catch (IllegalStateException e) { // 이메일 미인증 등
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        }
    }

    /** 내 프로필 조회: JWT 필터가 넣어준 request attribute 사용 */
    @GetMapping("/me")
    public ResponseEntity<?> me(@RequestAttribute(name = "username", required = false) String username) {
        if (username == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Unauthorized"));
        }
        return ResponseEntity.ok(userService.getProfile(username));
    }
}

