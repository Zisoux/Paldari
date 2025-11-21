package kr.ac.inhatc.paldari.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProfileBasicDto {

    private String gender;           // "male" | "female" | "other" | null
    private String birthdate;        // "yyyy-MM-dd" or null

    // ✅ 다중 국적
    private List<String> countries;  // 예: ["KR", "MY"]

    private String livingIn;         // 거주지 (예: "Seoul")

    private List<String> languages;  // 예: ["ko", "en"]

    private String introduction;     // 자기소개

    // 관심 태그
    private List<String> tags;

    // 🔥 누락된 필드 추가
    private List<String> regions;    // 활동 지역 (예: ["Seoul", "Busan"])
}
