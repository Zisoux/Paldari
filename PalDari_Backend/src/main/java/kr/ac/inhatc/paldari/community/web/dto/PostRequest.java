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

    // 🔽 추가 메타데이터
    private String language;     // '한국어', '영어', '일본어', ...

    /**
     * ⚠️ isForeigner / persona 는 서버에서
     *    "작성자 국적" vs "게시글 country" 를 비교해서 자동 계산함.
     *    클라이언트에서 보내더라도 현재는 사용하지 않는다.
     */
    private Boolean isForeigner; // true=외국인, false=내국인 (서버에서 계산)
    private String persona;      // '내국인' | '외국인' (서버에서 계산)

    // ⭐ 게시판 그룹: "정보" 또는 "소통"
    private String group;
}
