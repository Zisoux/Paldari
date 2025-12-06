package kr.ac.inhatc.paldari.rating.web.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RatingRequest {

    /**
     * 평가받는 사람의 userId (users.id)
     * ⚠ 절대 memberId, roomMemberId가 아님
     */
    @NotNull
    private Long buddyId;

    /**
     * 어떤 채팅방/매칭에 대한 평가인지 식별하기 위한 id
     * 필요 없으면 null 허용해도 됨
     */
    private Long chatRoomId;

    /**
     * 평점 (1~5)
     */
    @Min(1)
    @Max(5)
    private int score;

    /**
     * 선택사항 피드백
     */
    private String comment;
}
