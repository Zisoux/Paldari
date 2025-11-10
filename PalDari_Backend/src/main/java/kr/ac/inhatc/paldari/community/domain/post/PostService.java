package kr.ac.inhatc.paldari.community.domain.post;

import jakarta.transaction.Transactional;
import kr.ac.inhatc.paldari.community.web.dto.PostRequest;
import kr.ac.inhatc.paldari.community.web.dto.PostResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class PostService {

    private final PostRepository repo;

    @Transactional(Transactional.TxType.SUPPORTS)
    public List<PostResponse> listAll() {
        return repo.findAll(Sort.by(Sort.Direction.DESC, "createdAt"))
                .stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional(Transactional.TxType.SUPPORTS)
    public Page<PostResponse> list(Pageable pageable) {
        return repo.findAll(pageable)
                .map(this::toDto);
    }

    @Transactional(Transactional.TxType.SUPPORTS)
    public PostResponse get(Long id) {
        var p = repo.findById(id)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id));
        return toDto(p);
    }

    // 생성: Principal(username) 사용
    public PostResponse create(PostRequest req, String username) {
        if (username == null || username.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 필요");
        }

        Post saved = repo.save(new Post(
                username,
                req.getTitle(),
                req.getContent(),
                req.getCountry(),
                req.getCategory()
        ));

        return toDto(saved);
    }

    // 수정: 작성자만 가능
    public PostResponse update(Long id, PostRequest req, String username) {
        if (username == null || username.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 필요");
        }

        var p = repo.findById(id)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id));

        if (!username.equals(p.getAuthorUsername())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "수정 권한이 없습니다.");
        }

        p.setTitle(req.getTitle());
        p.setContent(req.getContent());
        p.setCountry(req.getCountry());
        p.setCategory(req.getCategory());

        return toDto(p);
    }

    // 삭제: 작성자만 가능
    public void delete(Long id, String username) {
        if (username == null || username.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 필요");
        }

        var p = repo.findById(id)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id));

        if (!username.equals(p.getAuthorUsername())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "삭제 권한이 없습니다.");
        }

        try {
            repo.delete(p);
        } catch (EmptyResultDataAccessException e) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id);
        }
    }

    private PostResponse toDto(Post p) {
        return new PostResponse(
                p.getId(),
                p.getAuthorUsername(),
                p.getTitle(),
                p.getContent(),
                p.getCountry(),
                p.getCategory(),
                p.getCreatedAt() != null ? p.getCreatedAt().toString() : null
        );
    }
}
