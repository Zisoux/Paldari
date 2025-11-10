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
}
