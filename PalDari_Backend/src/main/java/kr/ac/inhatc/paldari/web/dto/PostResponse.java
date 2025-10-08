package kr.ac.inhatc.paldari.web.dto;

import java.time.LocalDateTime;

public class PostResponse {
    private Long id;
    private Long memberId;
    private String title;
    private String content;
    private LocalDateTime createdAt;

    public PostResponse(Long id, Long memberId, String title, String content, LocalDateTime createdAt) {
        this.id = id;
        this.memberId = memberId;
        this.title = title;
        this.content = content;
        this.createdAt = createdAt;
    }

    public Long getId() { return id; }
    public Long getMemberId() { return memberId; }
    public String getTitle() { return title; }
    public String getContent() { return content; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
