package kr.ac.inhatc.paldari.community.web.controller;

import kr.ac.inhatc.paldari.community.domain.post.PostService;
import kr.ac.inhatc.paldari.community.web.dto.PostRequest;
import kr.ac.inhatc.paldari.community.web.dto.PostResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/api/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostService service;

    // 전체 목록 (공개)
    @GetMapping
    public List<PostResponse> list() {
        return service.listAll();
    }

    // 단건 조회 (공개)
    @GetMapping("/{id}")
    public PostResponse get(@PathVariable Long id) {
        return service.get(id);
    }

    // 내 글 목록 (로그인 필요)
    @GetMapping("/me")
    public List<PostResponse> myPosts(@AuthenticationPrincipal Jwt jwt) {
        Long memberId = service.getMemberIdByUsername(jwt.getSubject());
        return service.listMyPosts(memberId);
    }

    // 글 작성 (로그인 필요)
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PostResponse create(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody PostRequest req) {
        Long memberId = service.getMemberIdByUsername(jwt.getSubject());
        return service.create(memberId, req);
    }

    // 글 수정 (로그인 필요)
    @PutMapping("/{id}")
    public PostResponse update(@PathVariable Long id,
                               @AuthenticationPrincipal Jwt jwt,
                               @Valid @RequestBody PostRequest req) {
        Long memberId = service.getMemberIdByUsername(jwt.getSubject());
        return service.update(id, memberId, req);
    }

    // 글 삭제 (로그인 필요)
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        Long memberId = service.getMemberIdByUsername(jwt.getSubject());
        service.delete(id, memberId);
    }
}
