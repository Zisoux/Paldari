package kr.ac.inhatc.paldari.auth.service;

import jakarta.transaction.Transactional;
import kr.ac.inhatc.paldari.auth.dto.ProfileBasicDto;
import kr.ac.inhatc.paldari.auth.dto.UpdateProfileBasicRequest;
import kr.ac.inhatc.paldari.auth.entity.*;
import kr.ac.inhatc.paldari.auth.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
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

    // ====================== 공통 ======================
    private User getUserOrThrow(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + username));
    }

    private static String emptyToNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    // ====================== Basic (내 정보) ======================

    /** 내 정보 조회 (DTO 반환) */
    public ProfileBasicDto getBasic(String username) {
        User u = getUserOrThrow(username);

        // 🔹 태그/지역도 같이 조회해서 DTO에 담는다.
        List<String> tags = tagRepository.findByUser(u).stream()
                .map(UserTag::getTag)
                .collect(Collectors.toList());

        List<String> regions = regionRepository.findByUser(u).stream()
                .map(UserRegion::getRegion)
                .collect(Collectors.toList());

        ProfileBasicDto dto = new ProfileBasicDto();
        dto.setGender(emptyToNull(u.getGender()));
        dto.setBirthdate(u.getBirthdate() == null ? null : u.getBirthdate().toString()); // yyyy-MM-dd
        dto.setCountry(emptyToNull(u.getCountry()));
        dto.setLivingIn(emptyToNull(u.getLivingIn()));
        dto.setLanguage(emptyToNull(u.getLanguage()));
        dto.setIntroduction(emptyToNull(u.getIntroduction()));

        // 🔹 추가된 필드 세팅
        dto.setTags(tags);
        dto.setRegions(regions);

        return dto;
    }

    /**
     * 내 정보 부분 수정 (null 은 “수정 안 함”, 빈문자열은 null 로 저장)
     * 저장 후 최신 DTO 반환
     */
    public ProfileBasicDto updateBasic(String username, UpdateProfileBasicRequest req) {
        User u = getUserOrThrow(username);

        // ----- User 엔티티 기본 필드 업데이트 -----
        if (req.getGender() != null) {
            u.setGender(emptyToNull(req.getGender()));
        }
        if (req.getBirthdate() != null) {
            String b = emptyToNull(req.getBirthdate());
            if (b == null) {
                u.setBirthdate(null);
            } else {
                // 형식 검증: 잘못된 형식이면 IllegalArgumentException 던져서 400으로 매핑되게 하거나
                // GlobalExceptionHandler에서 메시지 변환
                try {
                    u.setBirthdate(LocalDate.parse(b)); // ISO yyyy-MM-dd
                } catch (DateTimeParseException e) {
                    throw new IllegalArgumentException("Invalid birthdate format (expected yyyy-MM-dd): " + b);
                }
            }
        }
        if (req.getCountry() != null) {
            u.setCountry(emptyToNull(req.getCountry()));
        }
        if (req.getLivingIn() != null) {
            u.setLivingIn(emptyToNull(req.getLivingIn()));
        }
        if (req.getLanguage() != null) {
            u.setLanguage(emptyToNull(req.getLanguage()));
        }
        if (req.getIntroduction() != null) {
            u.setIntroduction(emptyToNull(req.getIntroduction()));
        }

        // ----- 태그 업데이트 (정책: 태그 = 코드, 문자열 그대로 보관) -----
        // null  : 태그 변경 안 함
        // []    : 기존 태그 모두 삭제
        // [..]  : 기존 태그 모두 지우고, 새 리스트로 교체
        if (req.getTags() != null) {
            List<String> normTags = req.getTags().stream()
                    .filter(t -> t != null && !t.trim().isEmpty())
                    .map(String::trim)
                    .distinct()
                    .collect(Collectors.toList());

            // 기존 태그 전체 삭제 후 다시 저장
            List<UserTag> existing = tagRepository.findByUser(u);
            tagRepository.deleteAll(existing);

            for (String t : normTags) {
                UserTag ut = new UserTag();
                ut.setUser(u);
                ut.setTag(t); // "LIFE", "STUDY" 같은 코드 그대로 저장
                tagRepository.save(ut);
            }
        }

        // ----- 지역 업데이트 (정책: 지역 = 라벨 문자열 그대로 보관) -----
        // null  : 지역 변경 안 함
        // []    : 기존 지역 모두 삭제
        // [..]  : 기존 지역 모두 지우고, 새 리스트로 교체
        if (req.getRegions() != null) {
            List<String> normRegions = req.getRegions().stream()
                    .filter(r -> r != null && !r.trim().isEmpty())
                    .map(String::trim)
                    .distinct()
                    .collect(Collectors.toList());

            // 기존 지역 전체 삭제 후 다시 저장
            List<UserRegion> existingRegions = regionRepository.findByUser(u);
            regionRepository.deleteAll(existingRegions);

            for (String r : normRegions) {
                UserRegion ur = new UserRegion();
                ur.setUser(u);
                ur.setRegion(r); // "Seoul", "Kuala Lumpur" 같은 라벨 문자열 그대로 저장
                regionRepository.save(ur);
            }
        }

        userRepository.save(u);
        return getBasic(username);
    }

    // ====================== Settings ======================

    public Map<String, Object> getSettings(String username) {
        User user = getUserOrThrow(username);
        UserSettings s = settingsRepository.findByUser(user)
                .orElseGet(() -> {
                    UserSettings ns = new UserSettings();
                    ns.setUser(user);
                    // 엔티티 디폴트(true/true/false)가 있다면 그대로 사용
                    return settingsRepository.save(ns);
                });

        // boolean primitive만 담으므로 Map.of 사용 안전
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
        if (allowMatching != null)     s.setAllowMatching(allowMatching);
        if (realtimeTranslation != null) s.setRealtimeTranslation(realtimeTranslation);

        settingsRepository.save(s);

        return Map.of(
                "allowNotification", s.isAllowNotification(),
                "allowMatching", s.isAllowMatching(),
                "realtimeTranslation", s.isRealtimeTranslation()
        );
    }

    // ====================== Tags ======================

    public List<String> getTags(String username) {
        User user = getUserOrThrow(username);
        return tagRepository.findByUser(user).stream()
                .map(UserTag::getTag)
                .collect(Collectors.toList());
    }

    public List<String> addTag(String username, String tag) {
        User user = getUserOrThrow(username);
        String norm = tag == null ? "" : tag.trim();
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
        String norm = tag == null ? "" : tag.trim();
        if (!norm.isEmpty()) {
            tagRepository.deleteByUserAndTag(user, norm);
        }
        return getTags(username);
    }

    // ====================== Regions ======================

    public List<String> getRegions(String username) {
        User user = getUserOrThrow(username);
        return regionRepository.findByUser(user).stream()
                .map(UserRegion::getRegion)
                .collect(Collectors.toList());
    }

    public List<String> addRegion(String username, String region) {
        User user = getUserOrThrow(username);
        String norm = region == null ? "" : region.trim();
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
        String norm = region == null ? "" : region.trim();
        if (!norm.isEmpty()) {
            regionRepository.deleteByUserAndRegion(user, norm);
        }
        return getRegions(username);
    }
}
