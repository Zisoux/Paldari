package kr.ac.inhatc.paldari.rating.web.dto;

import kr.ac.inhatc.paldari.rating.domain.Rating;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class RatingResponse {

    private Long id;
    private Long raterId;
    private Long buddyId;
    private Long chatRoomId;
    private int score;
    private String comment;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static RatingResponse from(Rating rating) {
        return RatingResponse.builder()
                .id(rating.getId())
                .raterId(rating.getRater().getId())
                .buddyId(rating.getBuddy().getId())
                .chatRoomId(rating.getChatRoomId())
                .score(rating.getScore())
                .comment(rating.getComment())
                .createdAt(rating.getCreatedAt())
                .updatedAt(rating.getUpdatedAt())
                .build();
    }
}
