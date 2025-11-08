package kr.ac.inhatc.paldari.community.web.dto;

import java.time.LocalDateTime;

public class CommentResponse {
    private Long id;
    private Long postId;
    private String content;
    private LocalDateTime createdAt;

    public CommentResponse() {}

    public CommentResponse(Long id, Long postId, String content, LocalDateTime createdAt) {
        this.id = id;
        this.postId = postId;
        this.content = content;
        this.createdAt = createdAt;
    }

    public Long getId() { return id; }
    public Long getPostId() { return postId; }
    public String getContent() { return content; }
    public LocalDateTime getCreatedAt() { return createdAt; }

    public void setId(Long id) { this.id = id; }
    public void setPostId(Long postId) { this.postId = postId; }
    public void setContent(String content) { this.content = content; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
