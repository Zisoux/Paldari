package kr.ac.inhatc.paldari.rating.web.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class RatingSummaryDto {

    private double average;   // 평균 평점
    private long totalCount;  // 전체 개수

    private long count1;
    private long count2;
    private long count3;
    private long count4;
    private long count5;
}
