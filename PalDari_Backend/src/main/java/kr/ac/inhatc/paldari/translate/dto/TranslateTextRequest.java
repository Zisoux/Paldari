package kr.ac.inhatc.paldari.translate.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TranslateTextRequest {
    private String sourceLang; // 예: "ko"
    private String targetLang; // 예: "en"
    private String text;       // 번역할 문장
}
