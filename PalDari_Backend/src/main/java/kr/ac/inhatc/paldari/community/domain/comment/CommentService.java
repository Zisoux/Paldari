package kr.ac.inhatc.paldari.community.domain.comment;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.util.List;
import java.util.stream.Collectors;

import kr.ac.inhatc.paldari.community.domain.post.PostRepository;
import kr.ac.inhatc.paldari.community.domain.post.Post;
import kr.ac.inhatc.paldari.community.web.dto.CommentRequest;
import kr.ac.inhatc.paldari.community.web.dto.CommentResponse;

@Service
@Transactional
public class CommentService {
    private final CommentRepository commentRepo;
    private final PostRepository postRepo;

    public CommentService(CommentRepository commentRepo, PostRepository postRepo) {
        this.commentRepo = commentRepo;
        this.postRepo = postRepo;
    }

    public List<CommentResponse> listByPost(Long postId) {
        if (!postRepo.existsById(postId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + postId);
        }
        return commentRepo.findByPostIdOrderByCreatedAtAsc(postId).stream()
                .map(c -> new CommentResponse(c.getId(), c.getPost().getId(), c.getContent(), c.getCreatedAt()))
                .collect(Collectors.toList());
    }

    public CommentResponse get(Long postId, Long commentId) {
        Comment c = commentRepo.findById(commentId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Comment not found: " + commentId));
        if (!c.getPost().getId().equals(postId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Comment not found on post: " + commentId);
        }
        return new CommentResponse(c.getId(), c.getPost().getId(), c.getContent(), c.getCreatedAt());
    }

    public CommentResponse create(Long postId, CommentRequest req) {
        Post p = postRepo.findById(postId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + postId));
        Comment c = new Comment(p, req.getContent());
        Comment saved = commentRepo.save(c);
        return new CommentResponse(saved.getId(), saved.getPost().getId(), saved.getContent(), saved.getCreatedAt());
    }

    public CommentResponse update(Long postId, Long commentId, CommentRequest req) {
        Comment c = commentRepo.findById(commentId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Comment not found: " + commentId));
        if (!c.getPost().getId().equals(postId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Comment not found on post: " + commentId);
        }
        c.setContent(req.getContent());
        return new CommentResponse(c.getId(), c.getPost().getId(), c.getContent(), c.getCreatedAt());
    }

    public void delete(Long postId, Long commentId) {
        Comment c = commentRepo.findById(commentId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Comment not found: " + commentId));
        if (!c.getPost().getId().equals(postId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Comment not found on post: " + commentId);
        }
        commentRepo.deleteById(commentId);
    }
}
