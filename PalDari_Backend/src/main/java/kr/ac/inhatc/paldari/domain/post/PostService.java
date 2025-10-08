package kr.ac.inhatc.paldari.domain.post;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.util.List;
import java.util.stream.Collectors;

import kr.ac.inhatc.paldari.web.dto.PostRequest;
import kr.ac.inhatc.paldari.web.dto.PostResponse;

@Service
@Transactional
public class PostService {
    private final PostRepository repo;
    public PostService(PostRepository repo) { this.repo = repo; }

    public List<PostResponse> listAll() {
        return repo.findAll().stream()
                .map(p -> new PostResponse(p.getId(), p.getMemberId(), p.getTitle(), p.getContent(), p.getCreatedAt()))
                .collect(Collectors.toList());
    }

    public PostResponse get(Long id) {
        Post p = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id));
        return new PostResponse(p.getId(), p.getMemberId(), p.getTitle(), p.getContent(), p.getCreatedAt());
    }

    public PostResponse create(PostRequest req) {
        Post p = new Post(req.getMemberId(), req.getTitle(), req.getContent());
        Post saved = repo.save(p);
        return new PostResponse(saved.getId(), saved.getMemberId(), saved.getTitle(), saved.getContent(), saved.getCreatedAt());
    }

    public PostResponse update(Long id, PostRequest req) {
        Post p = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id));
        p.setTitle(req.getTitle());
        p.setContent(req.getContent());
        p.setUpdatedAt(java.time.LocalDateTime.now());
        return new PostResponse(p.getId(), p.getMemberId(), p.getTitle(), p.getContent(), p.getCreatedAt());
    }

    public void delete(Long id) {
        if (!repo.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id);
        }
        repo.deleteById(id);
    }
}
