package kr.ac.inhatc.paldari.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProfileBasicDto {
    private String gender;        // "male" | "female" | "other" | null
    private String birthdate;     // "yyyy-MM-dd" or null
    private String country;       // 국적 (예: "KR")
    private String livingIn;      // 거주지 (예: "Seoul")
    private List<String> languages;     // 언어 (예: "ko")
    private String introduction;  // 자기소개

    // 🔹 추가: 태그(코드), 지역(라벨 문자열)
    // 예) tags   = ["LIFE", "STUDY"]
    //     regions = ["Seoul", "Kuala Lumpur"]
    private List<String> tags;
    private List<String> regions;
}
