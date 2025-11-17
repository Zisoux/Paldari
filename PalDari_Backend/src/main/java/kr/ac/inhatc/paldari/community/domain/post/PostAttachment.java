package kr.ac.inhatc.paldari.community.domain.post;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "post_attachments")
public class PostAttachment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 여러 첨부파일(PostAttachment)이 하나의 Post에 연결되는 구조
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", nullable = false)  // post_id NOT NULL 권장
    private Post post;                 // 기존 Post 엔티티

    // 실제로 접근 가능한 URL (예: /uploads/xxx.png)
    @Column(nullable = false)
    private String url;

    // 사용자가 업로드한 원본 파일명
    @Column(nullable = false)
    private String originalName;

    // 업로드/저장 시각
    @Column(nullable = false)
    private LocalDateTime createdAt;

    // === 기본 생성자 (JPA용) ===
    public PostAttachment() {
    }

    // === 편의 생성자 ===
    public PostAttachment(Post post, String url, String originalName) {
        this.post = post;
        this.url = url;
        this.originalName = originalName;
        this.createdAt = LocalDateTime.now();
    }

    // === 엔티티 저장 전 createdAt 자동 세팅 (혹시 null 이면) ===
    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
    }

    // === Getter / Setter ===

    public Long getId() {
        return id;
    }

    public Post getPost() {
        return post;
    }

    public void setPost(Post post) {
        this.post = post;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getOriginalName() {
        return originalName;
    }

    public void setOriginalName(String originalName) {
        this.originalName = originalName;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
