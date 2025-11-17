package kr.ac.inhatc.paldari.auth.service;

import jakarta.transaction.Transactional;
import kr.ac.inhatc.paldari.auth.dto.UserSettingsDto;
import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.entity.UserSettings;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.auth.repository.UserSettingsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserSettingsService {

    private final UserRepository userRepository;
    private final UserSettingsRepository userSettingsRepository;

    @Transactional
    public UserSettingsDto getOrCreateSettings(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        UserSettings settings = userSettingsRepository.findByUser(user)
                .orElseGet(() -> {
                    UserSettings s = new UserSettings();
                    s.setUser(user);
                    // allowNotification / allowMatching / realtimeTranslation 은
                    // 엔티티 기본값(true/true/false) 사용
                    return userSettingsRepository.save(s);
                });

        return UserSettingsDto.from(settings);
    }

    @Transactional
    public UserSettingsDto updateRealtimeTranslation(Long userId, boolean enabled) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        UserSettings settings = userSettingsRepository.findByUser(user)
                .orElseGet(() -> {
                    UserSettings s = new UserSettings();
                    s.setUser(user);
                    return userSettingsRepository.save(s);
                });

        settings.setRealtimeTranslation(enabled);
        return UserSettingsDto.from(settings);
    }

    // 나중에 매칭 허용 토글도 연결하고 싶으면 이런 메서드 추가하면 됨:
    // @Transactional
    // public UserSettingsDto updateAllowMatching(Long userId, boolean allow) { ... }
}
