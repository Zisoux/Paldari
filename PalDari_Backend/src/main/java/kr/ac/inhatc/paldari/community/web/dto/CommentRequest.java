package kr.ac.inhatc.paldari.community.web.dto;

import jakarta.validation.constraints.NotBlank;

public class CommentRequest {
    @NotBlank
    private String content;

    public CommentRequest() {}
    public CommentRequest(String content) { this.content = content; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
}
