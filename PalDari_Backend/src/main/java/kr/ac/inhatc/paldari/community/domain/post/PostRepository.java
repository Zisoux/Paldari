package kr.ac.inhatc.paldari.community.domain.post;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PostRepository extends JpaRepository<Post, Long> {

    /**
     * 페르소나 코드(LOCAL / FOREIGN)로 필터링해서 최신순 조회
     */
    List<Post> findByPersonaOrderByCreatedAtDesc(String persona);
}
