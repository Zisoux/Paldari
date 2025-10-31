package kr.ac.inhatc.paldari.web.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.List;

import kr.ac.inhatc.paldari.domain.post.PostService;
import kr.ac.inhatc.paldari.web.dto.PostRequest;
import kr.ac.inhatc.paldari.web.dto.PostResponse;

@RestController
@RequestMapping("/api/posts")
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // 개발용
public class PostController {

    private final PostService service;

    @GetMapping
    public List<PostResponse> list() {
        // 필요하면 최신순 정렬은 서비스에서 처리 (예: findAll(Sort.by(DESC, "createdAt")))
        return service.listAll();
    }

    @GetMapping("/{id}")
    public PostResponse get(@PathVariable Long id) {
        return service.get(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED) // 201
    public PostResponse create(@Valid @RequestBody PostRequest req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    public PostResponse update(@PathVariable Long id, @Valid @RequestBody PostRequest req) {
        return service.update(id, req); // 200 OK
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT) // 204
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
