package kr.ac.inhatc.paldari.auth.controller;

import kr.ac.inhatc.paldari.auth.dto.UserSettingsDto;
import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.auth.service.UserSettingsService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
public class UserSettingsController {

    private final UserSettingsService userSettingsService;
    private final UserRepository userRepository;

    /**
     * Authentication.getName() = 항상 username 이라고 가정하고,
     * username으로 User 조회 후 id를 가져오는 헬퍼 메서드.
     */
    private Long currentUserId(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new IllegalStateException("인증되지 않은 사용자입니다.");
        }

        String username = authentication.getName(); // 예: "admin", "jisoo", ...

        User user = userRepository.findByUsername(username)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다: " + username));

        return user.getId();
    }

    @GetMapping("/me")
    public UserSettingsDto getMySettings(Authentication authentication) {
        Long userId = currentUserId(authentication);
        return userSettingsService.getOrCreateSettings(userId);
    }

    public record ToggleRequest(boolean enabled) {}

    @PutMapping("/me/translate")
    public UserSettingsDto toggleRealtimeTranslation(
            Authentication authentication,
            @RequestBody ToggleRequest request
    ) {
        Long userId = currentUserId(authentication);
        return userSettingsService.updateRealtimeTranslation(userId, request.enabled());
    }
}
