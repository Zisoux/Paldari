package kr.ac.inhatc.paldari.web.controller;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import java.util.List;
import kr.ac.inhatc.paldari.domain.post.PostService;
import kr.ac.inhatc.paldari.web.dto.PostRequest;
import kr.ac.inhatc.paldari.web.dto.PostResponse;

@RestController
@RequestMapping("/api/posts")
@CrossOrigin(origins = "*") // 개발용: 에뮬/프론트에서 호출 가능하도록 임시 허용
public class PostController {
    private final PostService service;
    public PostController(PostService service) { this.service = service; }

    @GetMapping
    public List<PostResponse> list() { return service.listAll(); }

    @GetMapping("/{id}")
    public PostResponse get(@PathVariable Long id) { return service.get(id); }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PostResponse create(@Valid @RequestBody PostRequest req) { return service.create(req); }

    @PutMapping("/{id}")
    public PostResponse update(@PathVariable Long id, @Valid @RequestBody PostRequest req) { return service.update(id, req); }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) { service.delete(id); }
}

