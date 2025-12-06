package kr.ac.inhatc.paldari.matching.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class MatchingChatRequest {

    // Flutter에서 보내는 JSON 키: { "targetUserId": 3 }
    private Long targetUserId;
}
