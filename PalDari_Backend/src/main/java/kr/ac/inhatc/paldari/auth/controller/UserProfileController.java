package kr.ac.inhatc.paldari.auth.controller;

import kr.ac.inhatc.paldari.auth.dto.ProfileBasicDto;
import kr.ac.inhatc.paldari.auth.dto.UpdateProfileBasicRequest;
import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.auth.service.UserProfileService;
import kr.ac.inhatc.paldari.rating.domain.RatingService;
import kr.ac.inhatc.paldari.rating.web.dto.RatingSummaryDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/profile")
@RequiredArgsConstructor
public class UserProfileController {

    private final UserProfileService userProfileService;
    private final UserRepository userRepository;   // 존재 확인용
    private final RatingService ratingService;     // ⭐ 평점 요약용

    private String username(Principal principal) {
        if (principal == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED");
        }
        return principal.getName();
    }

    // ========== Rating Summary ==========

    /** 내 평점 요약 조회 */
    @GetMapping("/rating-summary")
    public RatingSummaryDto getMyRatingSummary(Principal principal) {
        String uname = username(principal);

        User u = userRepository.findByUsername(uname)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        // buddyId = User.id 기준으로 요약 조회
        return ratingService.getSummaryForBuddy(u.getId());
    }

    // ========== Settings ==========

    /** 내 환경설정 조회 */
    @GetMapping("/settings")
    public ResponseEntity<?> getSettings(Principal principal) {
        String uname = username(principal);
        Map<String, Object> settings = userProfileService.getSettings(uname);
        return ResponseEntity.ok(settings);
    }

    /**
     * 환경설정 수정 (부분 업데이트)
     * PATCH /api/profile/settings
     * {
     *   "allowNotification": true/false,
     *   "allowMatching": true/false,
     *   "realtimeTranslation": true/false
     * }
     */
    @PatchMapping("/settings")
    public ResponseEntity<?> updateSettings(
            @RequestBody Map<String, Object> body,
            Principal principal
    ) {
        String uname = username(principal);

        Boolean allowNotification = body.containsKey("allowNotification")
                ? toBool(body.get("allowNotification"))
                : null;
        Boolean allowMatching = body.containsKey("allowMatching")
                ? toBool(body.get("allowMatching"))
                : null;
        Boolean realtimeTranslation = body.containsKey("realtimeTranslation")
                ? toBool(body.get("realtimeTranslation"))
                : null;

        Map<String, Object> updated = userProfileService.updateSettings(
                uname,
                allowNotification,
                allowMatching,
                realtimeTranslation
        );
        return ResponseEntity.ok(updated);
    }

    // ========== Basic Profile ==========

    /** 내 정보 조회 (DTO) */
    @GetMapping("/basic")
    public ResponseEntity<ProfileBasicDto> getBasic(Principal principal) {
        String uname = username(principal);
        ProfileBasicDto dto = userProfileService.getBasic(uname);
        return ResponseEntity.ok(dto);
    }

    /** 내 정보 부분 수정 (DTO) */
    @PatchMapping("/basic")
    public ResponseEntity<ProfileBasicDto> updateBasic(
            @RequestBody UpdateProfileBasicRequest req,
            Principal principal
    ) {
        String uname = username(principal);
        ProfileBasicDto dto = userProfileService.updateBasic(uname, req);
        return ResponseEntity.ok(dto);
    }

    // ========== Tags ==========

    /** 내 태그 조회 -> { "items": ["#생활", "#학업"] } */
    @GetMapping("/tags")
    public ResponseEntity<?> getTags(Principal principal) {
        String uname = username(principal);
        List<String> tags = userProfileService.getTags(uname);
        return ResponseEntity.ok(Map.of("items", tags));
    }

    /** 태그 추가 -> { "tag": "#생활" } */
    @PostMapping("/tags")
    public ResponseEntity<?> addTag(
            @RequestBody Map<String, String> body,
            Principal principal
    ) {
        String uname = username(principal);
        String tag = (body.getOrDefault("tag", "")).trim();
        if (tag.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "tag 는 필수입니다."));
        }
        List<String> tags = userProfileService.addTag(uname, tag);
        return ResponseEntity.ok(Map.of("items", tags));
    }

    /** 태그 삭제 -> { "tag": "#생활" } */
    @DeleteMapping("/tags")
    public ResponseEntity<?> removeTag(
            @RequestBody Map<String, String> body,
            Principal principal
    ) {
        String uname = username(principal);
        String tag = (body.getOrDefault("tag", "")).trim();
        if (tag.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "tag 는 필수입니다."));
        }
        List<String> tags = userProfileService.removeTag(uname, tag);
        return ResponseEntity.ok(Map.of("items", tags));
    }

    // ========== Regions ==========

    /** 내 지역 조회 -> { "items": ["서울", "쿠알라룸푸르"] } */
    @GetMapping("/regions")
    public ResponseEntity<?> getRegions(Principal principal) {
        String uname = username(principal);
        List<String> regions = userProfileService.getRegions(uname);
        return ResponseEntity.ok(Map.of("items", regions));
    }

    /** 지역 추가 -> { "region": "서울" } */
    @PostMapping("/regions")
    public ResponseEntity<?> addRegion(
            @RequestBody Map<String, String> body,
            Principal principal
    ) {
        String uname = username(principal);
        String region = (body.getOrDefault("region", "")).trim();
        if (region.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "region 은 필수입니다."));
        }
        List<String> regions = userProfileService.addRegion(uname, region);
        return ResponseEntity.ok(Map.of("items", regions));
    }

    /** 지역 삭제 -> { "region": "서울" } */
    @DeleteMapping("/regions")
    public ResponseEntity<?> removeRegion(
            @RequestBody Map<String, String> body,
            Principal principal
    ) {
        String uname = username(principal);
        String region = (body.getOrDefault("region", "")).trim();
        if (region.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "region 은 필수입니다."));
        }
        List<String> regions = userProfileService.removeRegion(uname, region);
        return ResponseEntity.ok(Map.of("items", regions));
    }

    // ========== 내부 유틸 ==========

    private Boolean toBool(Object v) {
        if (v == null) return null;
        if (v instanceof Boolean b) return b;
        if (v instanceof Number n) return n.intValue() != 0;
        String s = v.toString().trim().toLowerCase();
        if (s.isEmpty()) return null;
        return s.equals("true") || s.equals("1") || s.equals("y") || s.equals("yes");
    }
}
