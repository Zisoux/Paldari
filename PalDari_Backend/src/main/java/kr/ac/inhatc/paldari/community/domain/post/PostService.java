package kr.ac.inhatc.paldari.community.domain.post;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.community.web.dto.PostRequest;
import kr.ac.inhatc.paldari.community.web.dto.PostResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class PostService {

    private final PostRepository repo;
    private final UserRepository userRepository;

    // username -> memberId 변환
    @Transactional(readOnly = true)
    public Long getMemberIdByUsername(String username) {
        return userRepository.findByUsername(username)
                .map(User::getId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
    }

    // 전체 목록
    @Transactional(readOnly = true)
    public List<PostResponse> listAll() {
        return repo.findAll(Sort.by(Sort.Direction.DESC, "createdAt"))
                .stream()
                .map(p -> new PostResponse(p.getId(), p.getMemberId(), p.getTitle(), p.getContent(), p.getCreatedAt()))
                .toList();
    }

    // 페이징 버전
    @Transactional(readOnly = true)
    public Page<PostResponse> list(Pageable pageable) {
        return repo.findAll(pageable)
                .map(p -> new PostResponse(p.getId(), p.getMemberId(), p.getTitle(), p.getContent(), p.getCreatedAt()));
    }

    // 단건 조회
    @Transactional(readOnly = true)
    public PostResponse get(Long id) {
        var p = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id));
        return new PostResponse(p.getId(), p.getMemberId(), p.getTitle(), p.getContent(), p.getCreatedAt());
    }

    // 내 글 목록
    @Transactional(readOnly = true)
    public List<PostResponse> listMyPosts(Long memberId) {
        return repo.findByMemberIdOrderByCreatedAtDesc(memberId)
                .stream()
                .map(p -> new PostResponse(p.getId(), p.getMemberId(), p.getTitle(), p.getContent(), p.getCreatedAt()))
                .toList();
    }

    // 글 생성
    public PostResponse create(Long memberId, PostRequest req) {
        Post saved = repo.save(new Post(memberId, req.getTitle(), req.getContent()));
        return new PostResponse(saved.getId(), saved.getMemberId(), saved.getTitle(), saved.getContent(), saved.getCreatedAt());
    }

    // 글 수정 (본인만)
    public PostResponse update(Long id, Long memberId, PostRequest req) {
        var p = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id));

        if (!p.getMemberId().equals(memberId))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "본인 글만 수정할 수 있습니다.");

        p.setTitle(req.getTitle());
        p.setContent(req.getContent());

        return new PostResponse(p.getId(), p.getMemberId(), p.getTitle(), p.getContent(), p.getCreatedAt());
    }

    // 글 삭제 (본인만)
    public void delete(Long id, Long memberId) {
        var p = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id));

        if (!p.getMemberId().equals(memberId))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "본인 글만 삭제할 수 있습니다.");

        repo.delete(p);
    }
}
