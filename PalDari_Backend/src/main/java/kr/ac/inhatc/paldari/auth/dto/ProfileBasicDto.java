package kr.ac.inhatc.paldari.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProfileBasicDto {
    private String gender;        // "male" | "female" | "other" | null
    private String birthdate;     // "yyyy-MM-dd" or null
    private String country;       // 국적 (예: "KR")
    private String livingIn;      // 거주지 (예: "Seoul")
    private String language;      // 언어 (예: "ko")
    private String introduction;  // 자기소개
}
