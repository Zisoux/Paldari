package kr.ac.inhatc.paldari.matching.controller;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.chats.dto.ChatRoomResponse;
import kr.ac.inhatc.paldari.matching.dto.MatchingChatRequest;
import kr.ac.inhatc.paldari.matching.dto.MatchingCondition;
import kr.ac.inhatc.paldari.matching.dto.PalSummaryResponse;
import kr.ac.inhatc.paldari.matching.service.MatchingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/matching")
public class MatchingController {

    private final MatchingService matchingService;
    private final UserRepository userRepository;   // 🔹 currentUserId()에서 사용

    /**
     * 조건 기반 후보 리스트
     * GET /api/matching/candidates
     */
    @GetMapping("/candidates")
    public List<PalSummaryResponse> getCandidates(
            Authentication authentication,
            @RequestParam(required = false) String nationality,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String region,
            @RequestParam(required = false) String gender,
            @RequestParam(required = false) Integer minAge,
            @RequestParam(required = false) Integer maxAge
    ) {
        Long userId = currentUserId(authentication);

        MatchingCondition condition = MatchingCondition.builder()
                .nationality(nationality)
                .category(category)
                .region(region)
                .gender(gender)
                .minAge(minAge)
                .maxAge(maxAge)
                .build();

        return matchingService.findMatchingCandidates(userId, condition);
    }

    /**
     * 조건 기반으로 "가장 잘 맞는 1명" 찾기
     * GET /api/matching/best
     * (프론트에서 이걸 쓰고 있다면 이런 식으로)
     */
    @GetMapping("/best")
    public PalSummaryResponse getBestMatch(
            Authentication authentication,
            @RequestParam(required = false) String nationality,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String region,
            @RequestParam(required = false) String gender,
            @RequestParam(required = false) Integer minAge,
            @RequestParam(required = false) Integer maxAge
    ) {
        Long userId = currentUserId(authentication);

        MatchingCondition condition = MatchingCondition.builder()
                .nationality(nationality)
                .category(category)
                .region(region)
                .gender(gender)
                .minAge(minAge)
                .maxAge(maxAge)
                .build();

        return matchingService.findBestMatch(userId, condition)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "조건에 맞는 Pal 없음"));
    }

    /**
     * 조건 없이 랜덤 Pal 1명
     * GET /api/matching/random
     */
    @GetMapping("/random")
    public PalSummaryResponse getRandomPal(Authentication authentication) {
        Long userId = currentUserId(authentication);
        return matchingService.pickRandomPal(userId);
    }

    /**
     * 매칭된 Pal과의 1:1 채팅방 생성/조회
     * POST /api/matching/chat
     *
     * 요청 바디: { "targetUserId": 3 }
     * 응답: ChatRoomResponse { roomId, name, subText ... }
     */
    @PostMapping("/chat")
    public ChatRoomResponse createChatForMatching(
            Authentication authentication,
            @RequestBody MatchingChatRequest request
    ) {
        Long meId = currentUserId(authentication);
        return matchingService.createOrGetChatRoom(meId, request.getTargetUserId());
    }

    // ---------- 공통 유틸 ----------

    private Long currentUserId(Authentication authentication) {
        if (authentication == null) {
            throw new IllegalStateException("인증 정보가 없습니다.");
        }

        String name = authentication.getName(); // "3" 또는 "admin" 같은 값

        // 1) 숫자로 들어올 경우(토큰에 userId 넣은 경우)
        try {
            return Long.parseLong(name);
        } catch (NumberFormatException ignored) {
            // 2) "admin" 처럼 username으로 들어온 경우
            User user = userRepository.findByUsername(name)
                    .orElseThrow(() ->
                            new IllegalStateException("사용자를 찾을 수 없습니다: " + name));
            return user.getId();
        }
    }
}
