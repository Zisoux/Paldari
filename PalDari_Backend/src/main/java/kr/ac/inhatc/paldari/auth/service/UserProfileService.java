package kr.ac.inhatc.paldari.auth.service;

import jakarta.transaction.Transactional;
import kr.ac.inhatc.paldari.auth.entity.*;
import kr.ac.inhatc.paldari.auth.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class UserProfileService {

    private final UserRepository userRepository;
    private final UserSettingsRepository settingsRepository;
    private final UserTagRepository tagRepository;
    private final UserRegionRepository regionRepository;

    private User getUserOrThrow(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + username));
    }

    // ===== Settings =====

    public Map<String, Object> getSettings(String username) {
        User user = getUserOrThrow(username);
        UserSettings s = settingsRepository.findByUser(user)
                .orElseGet(() -> {
                    UserSettings ns = new UserSettings();
                    ns.setUser(user);
                    // 기본값 true/true/false 는 엔티티 디폴트 사용
                    return settingsRepository.save(ns);
                });

        return Map.of(
                "allowNotification", s.isAllowNotification(),
                "allowMatching", s.isAllowMatching(),
                "realtimeTranslation", s.isRealtimeTranslation()
        );
    }

    public Map<String, Object> updateSettings(
            String username,
            Boolean allowNotification,
            Boolean allowMatching,
            Boolean realtimeTranslation
    ) {
        User user = getUserOrThrow(username);
        UserSettings s = settingsRepository.findByUser(user)
                .orElseGet(() -> {
                    UserSettings ns = new UserSettings();
                    ns.setUser(user);
                    return ns;
                });

        if (allowNotification != null) s.setAllowNotification(allowNotification);
        if (allowMatching != null) s.setAllowMatching(allowMatching);
        if (realtimeTranslation != null) s.setRealtimeTranslation(realtimeTranslation);

        settingsRepository.save(s);

        return Map.of(
                "allowNotification", s.isAllowNotification(),
                "allowMatching", s.isAllowMatching(),
                "realtimeTranslation", s.isRealtimeTranslation()
        );
    }

    // ===== Tags =====

    public List<String> getTags(String username) {
        User user = getUserOrThrow(username);
        return tagRepository.findByUser(user).stream()
                .map(UserTag::getTag)
                .collect(Collectors.toList());
    }

    public List<String> addTag(String username, String tag) {
        User user = getUserOrThrow(username);
        String norm = tag.trim();
        if (norm.isEmpty()) return getTags(username);

        if (!tagRepository.existsByUserAndTag(user, norm)) {
            UserTag ut = new UserTag();
            ut.setUser(user);
            ut.setTag(norm);
            tagRepository.save(ut);
        }
        return getTags(username);
    }

    public List<String> removeTag(String username, String tag) {
        User user = getUserOrThrow(username);
        String norm = tag.trim();
        if (!norm.isEmpty()) {
            tagRepository.deleteByUserAndTag(user, norm);
        }
        return getTags(username);
    }

    // ===== Regions =====

    public List<String> getRegions(String username) {
        User user = getUserOrThrow(username);
        return regionRepository.findByUser(user).stream()
                .map(UserRegion::getRegion)
                .collect(Collectors.toList());
    }

    public List<String> addRegion(String username, String region) {
        User user = getUserOrThrow(username);
        String norm = region.trim();
        if (norm.isEmpty()) return getRegions(username);

        if (!regionRepository.existsByUserAndRegion(user, norm)) {
            UserRegion ur = new UserRegion();
            ur.setUser(user);
            ur.setRegion(norm);
            regionRepository.save(ur);
        }
        return getRegions(username);
    }

    public List<String> removeRegion(String username, String region) {
        User user = getUserOrThrow(username);
        String norm = region.trim();
        if (!norm.isEmpty()) {
            regionRepository.deleteByUserAndRegion(user, norm);
        }
        return getRegions(username);
    }
}
