package kr.ac.inhatc.paldari.rating.web;

import jakarta.validation.Valid;
import kr.ac.inhatc.paldari.rating.domain.Rating;
import kr.ac.inhatc.paldari.rating.domain.RatingService;
import kr.ac.inhatc.paldari.rating.web.dto.RatingRequest;
import kr.ac.inhatc.paldari.rating.web.dto.RatingResponse;
import kr.ac.inhatc.paldari.rating.web.dto.RatingSummaryDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.security.Principal;

@RestController
@RequestMapping("/api/ratings")
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // 개발용
public class RatingController {

    private final RatingService ratingService;

    // ===== 내부 유틸 =====
    private String username(Principal principal) {
        if (principal == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED");
        }
        return principal.getName();
    }

    /**
     * 채팅방에서 Buddy 평점 남기기 / 수정
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RatingResponse rateBuddy(@Valid @RequestBody RatingRequest request,
                                    Principal principal) {

        // principal.getName() 은 username 으로 사용
        String raterUsername = principal.getName();
        Rating rating = ratingService.createOrUpdateRating(raterUsername, request);
        return RatingResponse.from(rating);
    }

    /**
     * 마이페이지 또는 다른 화면에서 Buddy의 평점 요약 조회
     */
    @GetMapping("/summary/{buddyId}")
    public RatingSummaryDto getSummary(@PathVariable Long buddyId) {
        return ratingService.getSummaryForBuddy(buddyId);
    }
}
