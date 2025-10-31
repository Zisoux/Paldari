package kr.ac.inhatc.paldari.domain.post;

import lombok.RequiredArgsConstructor;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

import kr.ac.inhatc.paldari.web.dto.PostRequest;
import kr.ac.inhatc.paldari.web.dto.PostResponse;

@Service
@RequiredArgsConstructor
@Transactional
public class PostService {

    private final PostRepository repo;

    // ✅ 최신순 목록
    @Transactional(readOnly = true)
    public List<PostResponse> listAll() {
        return repo.findAll(Sort.by(Sort.Direction.DESC, "createdAt"))
                .stream()
                .map(p -> new PostResponse(
                        p.getId(), p.getMemberId(), p.getTitle(), p.getContent(), p.getCreatedAt()
                ))
                .toList();
    }

    // ✅ (선택) 페이징 버전
    @Transactional(readOnly = true)
    public Page<PostResponse> list(Pageable pageable) {
        return repo.findAll(pageable)
                .map(p -> new PostResponse(
                        p.getId(), p.getMemberId(), p.getTitle(), p.getContent(), p.getCreatedAt()
                ));
    }

    @Transactional(readOnly = true)
    public PostResponse get(Long id) {
        var p = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id));
        return new PostResponse(
                p.getId(), p.getMemberId(), p.getTitle(), p.getContent(), p.getCreatedAt()
        );
    }

    public PostResponse create(PostRequest req) {
        // (권장) Controller에서 @Valid로 title/content null/blank 검증
        Post saved = repo.save(new Post(req.getMemberId(), req.getTitle(), req.getContent()));
        return new PostResponse(
                saved.getId(), saved.getMemberId(), saved.getTitle(), saved.getContent(), saved.getCreatedAt()
        );
    }

    public PostResponse update(Long id, PostRequest req) {
        var p = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id));
        p.setTitle(req.getTitle());
        p.setContent(req.getContent());
        // JPA 더티체킹으로 자동 flush; @PreUpdate가 updatedAt 세팅

        return new PostResponse(
                p.getId(), p.getMemberId(), p.getTitle(), p.getContent(), p.getCreatedAt()
        );
    }

    public void delete(Long id) {
        try {
            repo.deleteById(id); // ✅ 단일 쿼리
        } catch (EmptyResultDataAccessException e) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id);
        }
        // (선택) 캐시 사용 시: @CacheEvict(value="posts", allEntries=true)
    }
}
