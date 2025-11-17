package kr.ac.inhatc.paldari.rating.domain;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.rating.web.dto.RatingRequest;
import kr.ac.inhatc.paldari.rating.web.dto.RatingSummaryDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class RatingService {

    private final RatingRepository ratingRepository;
    private final UserRepository userRepository;

    /**
     * ⭐ 중복 방지 + 수정 지원
     */
    public Rating createOrUpdateRating(String raterUsername, RatingRequest request) {

        User rater = userRepository.findByUsername(raterUsername)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

        User buddy = userRepository.findById(request.getBuddyId())
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 Buddy입니다."));

        Long raterId = rater.getId();
        Long buddyId = buddy.getId();
        Long chatRoomId = request.getChatRoomId();

        // 🔍 기존 평점 조회
        var existingOpt = ratingRepository
                .findByBuddyIdAndRaterIdAndChatRoomId(buddyId, raterId, chatRoomId);

        if (existingOpt.isPresent()) {
            // 🔥 이미 존재 → update()만 사용
            Rating existing = existingOpt.get();
            existing.update(request.getScore(), request.getComment());

            return ratingRepository.save(existing);
        }

        // 🔥 신규 생성
        Rating rating = Rating.builder()
                .buddy(buddy)
                .rater(rater)
                .chatRoomId(chatRoomId)
                .score(request.getScore())
                .comment(request.getComment())
                .build();

        return ratingRepository.save(rating);
    }

    /**
     * 마이페이지용: 특정 유저가 받은 평점 요약
     */
    @Transactional(readOnly = true)
    public RatingSummaryDto getSummaryForBuddy(Long buddyId) {

        List<RatingRepository.ScoreCount> rows = ratingRepository.countByScore(buddyId);

        long[] counts = new long[6]; // index 1~5 사용
        long total = 0;
        long sum = 0;

        for (RatingRepository.ScoreCount row : rows) {
            int score = row.getScore();
            long cnt = row.getCnt();
            if (score >= 1 && score <= 5) {
                counts[score] = cnt;
                total += cnt;
                sum += (long) score * cnt;
            }
        }

        double avg = (total == 0) ? 0.0 : (double) sum / total;

        return RatingSummaryDto.builder()
                .average(avg)
                .totalCount(total)
                .count1(counts[1])
                .count2(counts[2])
                .count3(counts[3])
                .count4(counts[4])
                .count5(counts[5])
                .build();
    }
}
