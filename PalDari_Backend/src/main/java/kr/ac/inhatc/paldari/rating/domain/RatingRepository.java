package kr.ac.inhatc.paldari.rating.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface RatingRepository extends JpaRepository<Rating, Long> {

    // buddy(평가받은 사람) 기준으로 전체 평점
    List<Rating> findByBuddyId(Long buddyId);

    // 한 사람이 같은 매칭(채팅방)에 여러 번 평가 못 하게 하기 위한 검색
    Optional<Rating> findByBuddyIdAndRaterIdAndChatRoomId(Long buddyId,
                                                          Long raterId,
                                                          Long chatRoomId);

    // 점수별 개수 한 번에 가져오기
    @Query("""
            select r.score as score, count(r) as cnt
            from Rating r
            where r.buddy.id = :buddyId
            group by r.score
            """)
    List<ScoreCount> countByScore(@Param("buddyId") Long buddyId);

    interface ScoreCount {
        int getScore();
        long getCnt();
    }
}
