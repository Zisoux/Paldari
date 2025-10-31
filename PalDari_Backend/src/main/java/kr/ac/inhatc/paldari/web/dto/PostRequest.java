package kr.ac.inhatc.paldari.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class PostRequest {
    @NotNull(message = "memberId는 필수입니다.")
    private Long memberId;
    @NotBlank(message = "memberId는 필수입니다.")
    private String title;
    @NotBlank(message = "memberId는 필수입니다.")
    private String content;

    public PostRequest() {}

    public Long getMemberId() { return memberId; }
    public void setMemberId(Long memberId) { this.memberId = memberId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
}
