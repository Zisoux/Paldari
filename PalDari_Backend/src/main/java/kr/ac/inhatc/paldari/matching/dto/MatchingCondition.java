package kr.ac.inhatc.paldari.matching.dto;

import lombok.Builder;

@Builder
public record MatchingCondition(
        String nationality,  // BUDDY 국적
        String category,     // 카테고리 (태그와 매칭)
        String region,       // 활동 지역 (UserRegion 기반)
        String language,     // 사용 언어
        String gender,       // "남성" / "여성" / "무관" / "전체"
        Integer minAge,      // 최소 나이
        Integer maxAge       // 최대 나이
) {}
