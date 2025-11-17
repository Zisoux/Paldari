package kr.ac.inhatc.paldari.auth.dto;

import lombok.Data;

import java.util.List;

/** PATCH 부분수정: null이면 해당 필드는 변경하지 않음 */
@Data
public class UpdateProfileBasicRequest {
    private String gender;
    private String birthdate;   // "yyyy-MM-dd"
    private String country;
    private String livingIn;
    private String language;
    private String introduction;

    // 🔹 추가: 태그 / 지역도 프로필 기본정보에서 한 번에 수정 가능
    // null이면 “태그/지역은 건드리지 않음”
    // 빈 리스트([])면 “모두 삭제”
    private List<String> tags;      // 태그 코드 리스트 (예: ["LIFE", "STUDY"])
    private List<String> regions;   // 지역 라벨 리스트 (예: ["Seoul", "Paris"])
}
