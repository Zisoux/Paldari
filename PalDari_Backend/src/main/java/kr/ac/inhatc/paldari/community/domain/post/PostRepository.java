package kr.ac.inhatc.paldari.community.domain.post;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PostRepository extends JpaRepository<Post, Long> {
    // PostRepository.java
    List<Post> findByMemberIdOrderByCreatedAtDesc(Long memberId);

}
