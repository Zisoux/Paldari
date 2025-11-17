package kr.ac.inhatc.paldari.community.web.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

@Getter
@AllArgsConstructor
public class PostDetailResponse {

    private Long id;
    private String title;
    private String content;
    private String authorUsername;

    // 🔹 메타데이터 필드 추가
    private String country;
    private String category;
    private String language;
    private Boolean isForeigner;
    private String persona;

    // 🔹 첨부파일 목록
    private List<AttachmentDto> attachments;
}
