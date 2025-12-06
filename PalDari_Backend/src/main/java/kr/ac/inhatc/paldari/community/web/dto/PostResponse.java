package kr.ac.inhatc.paldari.community.web.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class PostResponse {
    private Long id;
    private String authorUsername;
    private String title;
    private String content;
    private String country;
    private String category;
    private String createdAt;

    private String language;
    private Boolean isForeigner;
    private String persona;

    // ⭐ 게시판 그룹 (정보 / 소통)
    private String group;
}
