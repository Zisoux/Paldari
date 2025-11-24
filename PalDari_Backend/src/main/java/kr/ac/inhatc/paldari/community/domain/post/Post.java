package kr.ac.inhatc.paldari.community.domain.post;

import jakarta.persistence.*;
import kr.ac.inhatc.paldari.auth.entity.User;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "posts")
public class Post {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 작성자 username (User 엔티티와 FK 안 걸고 문자열로 보관)
    @Column(name = "author_username", nullable = false, length = 50)
    private String authorUsername;

    // 🔥 User 엔티티와 FK 매핑
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private User author;


    @Column(nullable = false, length = 150)
    private String title;

    @Lob
    @Column(nullable = false)
    private String content;

    @Column(length = 50)
    private String country;

    @Column(length = 50)
    private String category;

    @Column(length = 50)
    private String language;

    @Column(name = "is_foreigner")
    private Boolean isForeigner;

    @Column(length = 50)
    private String persona;

    // ⭐ DB 컬럼명 post_group 에 맞춤
    @Column(name = "post_group", length = 20)
    private String group;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @OneToMany(
            mappedBy = "post",
            cascade = CascadeType.ALL,
            orphanRemoval = true
    )
    private List<PostAttachment> attachments = new ArrayList<>();

    protected Post() {}

    public Post(String authorUsername,
                String title,
                String content,
                String country,
                String category) {
        this.authorUsername = authorUsername;
        this.title = title;
        this.content = content;
        this.country = country;
        this.category = category;
    }

    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    // Getters / Setters

    public Long getId() { return id; }

    public String getAuthorUsername() { return authorUsername; }
    public void setAuthorUsername(String authorUsername) { this.authorUsername = authorUsername; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }

    public Boolean getIsForeigner() { return isForeigner; }
    public void setIsForeigner(Boolean isForeigner) { this.isForeigner = isForeigner; }

    public String getPersona() { return persona; }
    public void setPersona(String persona) { this.persona = persona; }

    public String getGroup() { return group; }
    public void setGroup(String group) { this.group = group; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }

    public List<PostAttachment> getAttachments() {
        return attachments;
    }

    public void setAttachments(List<PostAttachment> attachments) {
        this.attachments = attachments;
    }

    public User getAuthor() {
        return author;
    }

    public void setAuthor(User author) {
        this.author = author;
    }

    public void addAttachment(PostAttachment attachment) {
        attachments.add(attachment);
        attachment.setPost(this);
    }

    public void removeAttachment(PostAttachment attachment) {
        attachments.remove(attachment);
        attachment.setPost(null);
    }
}
