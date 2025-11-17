package kr.ac.inhatc.paldari.community.web.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PostRequest {
    @NotBlank(message = "제목은 필수입니다.")
    private String title;

    @NotBlank(message = "내용은 필수입니다.")
    private String content;

    private String country;
    private String category;

    // 🔽 추가
    private String language;     // '한국어', '영어' ...
    private Boolean isForeigner; // 불린 규격을 쓸 때
    private String persona;      // 텍스트 규격을 쓸 때 ('내국인'|'외국인')
}

