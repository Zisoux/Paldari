package kr.ac.inhatc.paldari.community.web.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.util.UriComponentsBuilder;
import jakarta.validation.Valid;

import java.net.URI;
import java.util.List;

import kr.ac.inhatc.paldari.community.domain.comment.CommentService;
import kr.ac.inhatc.paldari.community.web.dto.CommentRequest;
import kr.ac.inhatc.paldari.community.web.dto.CommentResponse;

@RestController
@RequestMapping("/api/posts/{postId}/comments")
public class CommentController {
    private final CommentService service;

    public CommentController(CommentService service) {
        this.service = service;
    }

    // 목록
    @GetMapping
    public List<CommentResponse> list(@PathVariable Long postId) {
        return service.listByPost(postId);
    }

    // 상세
    @GetMapping("/{id}")
    public CommentResponse get(@PathVariable Long postId, @PathVariable Long id) {
        return service.get(postId, id);
    }

    // 생성 (201 + Location header)
    @PostMapping
    public ResponseEntity<CommentResponse> create(@PathVariable Long postId,
                                                  @Valid @RequestBody CommentRequest req,
                                                  UriComponentsBuilder uriBuilder) {
        CommentResponse created = service.create(postId, req);
        URI location = uriBuilder.path("/api/posts/{postId}/comments/{id}")
                .buildAndExpand(postId, created.getId()).toUri();
        return ResponseEntity.created(location).body(created);
    }

    // 수정
    @PutMapping("/{id}")
    public CommentResponse update(@PathVariable Long postId, @PathVariable Long id, @Valid @RequestBody CommentRequest req) {
        return service.update(postId, id, req);
    }

    // 삭제
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long postId, @PathVariable Long id) {
        service.delete(postId, id);
    }
}
