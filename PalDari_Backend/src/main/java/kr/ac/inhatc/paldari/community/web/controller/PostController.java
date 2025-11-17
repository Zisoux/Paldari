package kr.ac.inhatc.paldari.community.web.controller;

import jakarta.validation.Valid;
import kr.ac.inhatc.paldari.community.domain.post.PostService;
import kr.ac.inhatc.paldari.community.web.dto.PostDetailResponse;
import kr.ac.inhatc.paldari.community.web.dto.PostRequest;
import kr.ac.inhatc.paldari.community.web.dto.PostResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/posts")
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // 개발용
public class PostController {

    private final PostService service;

    /**
     * 게시글 목록 조회
     * - 공개로 둘 건지, 인증 사용자만 보게 할 건지는 SecurityConfig에서 결정
     */
    @GetMapping
    public List<PostResponse> list() {
        return service.listAll();
    }

    /**
     * 게시글 단건 조회 + 첨부파일 목록 + 메타데이터(국가/카테고리/언어/내외국인/페르소나)
     */
    @GetMapping("/{id}")
    public PostDetailResponse get(@PathVariable Long id) {
        return service.getDetail(id);
    }

    /**
     * 게시글 작성
     * - JWT 인증 필요 (SecurityConfig에서 /api/posts POST는 authenticated)
     * - 작성자는 클라이언트에서 받지 않고, Principal(=JWT username)에서 가져온다.
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PostResponse create(@Valid @RequestBody PostRequest req,
                               Principal principal) {
        String username = principal.getName(); // JwtAuthenticationFilter에서 세팅한 username
        return service.create(req, username);
    }

    /**
     * 게시글 수정
     * - JWT 인증 필요
     * - 서비스에서 "작성자 == principal" 검사 후 아니면 예외 던지기
     */
    @PutMapping("/{id}")
    public PostResponse update(@PathVariable Long id,
                               @Valid @RequestBody PostRequest req,
                               Principal principal) {
        String username = principal.getName();
        return service.update(id, req, username);
    }

    /**
     * 게시글 삭제
     * - JWT 인증 필요
     * - 서비스에서 작성자/권한 체크
     */
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id,
                       Principal principal) {
        String username = principal.getName();
        service.delete(id, username);
    }
}
