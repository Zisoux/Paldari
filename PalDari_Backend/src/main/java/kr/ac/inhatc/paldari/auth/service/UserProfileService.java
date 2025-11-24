package kr.ac.inhatc.paldari.auth.service;

import jakarta.transaction.Transactional;
import kr.ac.inhatc.paldari.auth.dto.ProfileBasicDto;
import kr.ac.inhatc.paldari.auth.dto.UpdateProfileBasicRequest;
import kr.ac.inhatc.paldari.auth.entity.*;
import kr.ac.inhatc.paldari.auth.repository.*;
import kr.ac.inhatc.paldari.chats.entity.ChatRoom;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomMemberRepository;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomRepository;
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
    private final ChatRoomRepository chatRoomRepository;
    private final ChatRoomMemberRepository chatRoomMemberRepository;


    // ====================== 공통 ======================
    private User getUserOrThrow(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + username));
    }

    /** 공백 문자열은 null 로 정규화 */
    private static String emptyToNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    // ====================== Basic (내 정보) ======================

    /** 내 정보 조회 (DTO 반환) */
    public ProfileBasicDto getBasic(String username) {
        User u = getUserOrThrow(username);

        // 🔹 태그/지역 조회
        List<String> tags = tagRepository.findByUser(u).stream()
                .map(UserTag::getTag)
                .collect(Collectors.toList());

        List<String> regions = regionRepository.findByUser(u).stream()
                .map(UserRegion::getRegion)
                .collect(Collectors.toList());

        // 🔹 "ko,en,ja" -> ["ko","en","ja"]
        List<String> languages = null;
        String langRaw = u.getLanguage();
        if (langRaw != null && !langRaw.trim().isEmpty()) {
            languages = List.of(langRaw.split("\\s*,\\s*")); // 콤마 기준 split
        }

        ProfileBasicDto dto = new ProfileBasicDto();
        dto.setGender(emptyToNull(u.getGender()));
        dto.setBirthdate(u.getBirthdate() == null ? null : u.getBirthdate().toString()); // yyyy-MM-dd

        // ✅ 국적: 다중 국가 리스트 그대로 반환 (예: ["KR","MY"])
        dto.setCountries(u.getCountries());

        dto.setLivingIn(emptyToNull(u.getLivingIn()));
        dto.setLanguages(languages); // ✅ 리스트만 사용
        dto.setIntroduction(emptyToNull(u.getIntroduction()));

        dto.setTags(tags);
        dto.setRegions(regions);

        return dto;
    }

    /**
     * 공개 프로필 조회 (userId 기준)
     * - username 없이 userId 로 접근
     * - 기본 정보 + 태그/지역을 ProfileBasicDto 로 반환
     */
    public ProfileBasicDto getPublicProfile(Long userId) {
        User u = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        List<String> tags = tagRepository.findByUser(u).stream()
                .map(UserTag::getTag)
                .collect(Collectors.toList());

        List<String> regions = regionRepository.findByUser(u).stream()
                .map(UserRegion::getRegion)
                .collect(Collectors.toList());

        // 🔹 언어 리스트
        List<String> languages = null;
        String langRaw = u.getLanguage();
        if (langRaw != null && !langRaw.trim().isEmpty()) {
            languages = List.of(langRaw.split("\\s*,\\s*"));
        }

        ProfileBasicDto dto = new ProfileBasicDto();
        dto.setGender(emptyToNull(u.getGender()));
        dto.setBirthdate(u.getBirthdate() == null ? null : u.getBirthdate().toString()); // yyyy-MM-dd

        // ✅ 공개 프로필에도 국적 리스트 포함
        dto.setCountries(u.getCountries());

        dto.setLivingIn(emptyToNull(u.getLivingIn()));
        dto.setIntroduction(emptyToNull(u.getIntroduction()));
        dto.setLanguages(languages);   // ✅ 리스트만 사용
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

        // 성별
        if (req.getGender() != null) {
            u.setGender(emptyToNull(req.getGender()));
        }

        // 생년월일
        if (req.getBirthdate() != null) {
            String b = emptyToNull(req.getBirthdate());
            if (b == null) {
                u.setBirthdate(null);
            } else {
                try {
                    u.setBirthdate(LocalDate.parse(b)); // ISO yyyy-MM-dd
                } catch (DateTimeParseException e) {
                    throw new IllegalArgumentException("Invalid birthdate format (expected yyyy-MM-dd): " + b);
                }
            }
        }

        // ✅ 국적 리스트 업데이트
        // null  : 변경 안 함
        // []    : 전체 삭제
        // [..]  : 정규화 후 저장
        if (req.getCountries() != null) {
            List<String> normCountries = req.getCountries().stream()
                    .filter(c -> c != null && !c.trim().isEmpty())
                    .map(String::trim)
                    .distinct()
                    .collect(Collectors.toList());
            u.getCountries().clear();
            u.getCountries().addAll(normCountries);
        }

        // 거주지
        if (req.getLivingIn() != null) {
            u.setLivingIn(emptyToNull(req.getLivingIn()));
        }

        // 자기소개
        if (req.getIntroduction() != null) {
            u.setIntroduction(emptyToNull(req.getIntroduction()));
        }

        // ✅ 구사 언어 리스트 업데이트
        // null  : 언어 변경 안 함
        // []    : 기존 언어 모두 삭제
        // [..]  : 콤마로 join 해서 저장 ("ko,en,ja")
        if (req.getLanguages() != null) {
            if (req.getLanguages().isEmpty()) {
                u.setLanguage(null);
            } else {
                String joined = req.getLanguages().stream()
                        .filter(s -> s != null && !s.trim().isEmpty())
                        .map(String::trim)
                        .distinct()
                        .collect(Collectors.joining(","));
                u.setLanguage(joined); // 예: "ko,en,ja"
            }
        }

        // ----- 태그 업데이트 -----
        if (req.getTags() != null) {
            List<String> normTags = req.getTags().stream()
                    .filter(t -> t != null && !t.trim().isEmpty())
                    .map(String::trim)
                    .distinct()
                    .collect(Collectors.toList());

            List<UserTag> existing = tagRepository.findByUser(u);
            tagRepository.deleteAll(existing);

            for (String t : normTags) {
                UserTag ut = new UserTag();
                ut.setUser(u);
                ut.setTag(t);
                tagRepository.save(ut);
            }
        }

        // ----- 지역 업데이트 -----
        if (req.getRegions() != null) {
            List<String> normRegions = req.getRegions().stream()
                    .filter(r -> r != null && !r.trim().isEmpty())
                    .map(String::trim)
                    .distinct()
                    .collect(Collectors.toList());

            List<UserRegion> existingRegions = regionRepository.findByUser(u);
            regionRepository.deleteAll(existingRegions);

            for (String r : normRegions) {
                UserRegion ur = new UserRegion();
                ur.setUser(u);
                ur.setRegion(r);
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

        if (allowNotification != null)   s.setAllowNotification(allowNotification);
        if (allowMatching != null)       s.setAllowMatching(allowMatching);
        if (realtimeTranslation != null) s.setRealtimeTranslation(realtimeTranslation);

        settingsRepository.save(s);

        return Map.of(
                "allowNotification", s.isAllowNotification(),
                "allowMatching",     s.isAllowMatching(),
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
    @Transactional
    public void deleteAccount(String username) {
        User user = getUserOrThrow(username);

        // 1) 유저가 속한 채팅방 먼저 삭제 (멤버/메시지 자동 Cascade)
        List<ChatRoom> myRooms = chatRoomRepository.findByMembersUser(user);
        for (ChatRoom room : myRooms) {
            chatRoomRepository.delete(room);
        }

        // 2) 태그/지역/세팅 삭제
        tagRepository.deleteAll(tagRepository.findByUser(user));
        regionRepository.deleteAll(regionRepository.findByUser(user));
        settingsRepository.findByUser(user).ifPresent(settingsRepository::delete);

        // 3) 마지막으로 유저 삭제
        userRepository.delete(user);
    }


}
