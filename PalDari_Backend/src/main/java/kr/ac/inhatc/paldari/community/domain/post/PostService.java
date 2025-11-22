package kr.ac.inhatc.paldari.community.domain.post;

import jakarta.transaction.Transactional;
import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.community.web.dto.AttachmentDto;
import kr.ac.inhatc.paldari.community.web.dto.PostDetailResponse;
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

    private final UserRepository userRepository;

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

    // 🔹 기존 기본 조회 (필요하면 계속 사용)
    @Transactional(Transactional.TxType.SUPPORTS)
    public PostResponse get(Long id) {
        var p = repo.findById(id)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id));
        return toDto(p);
    }

    // 🔹 상세 조회: 첨부 + 메타데이터까지 포함
    @Transactional(Transactional.TxType.SUPPORTS)
    public PostDetailResponse getDetail(Long id) {
        var p = repo.findById(id)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found: " + id));

        var attachmentDtos = p.getAttachments()
                .stream()
                .map(a -> new AttachmentDto(
                        a.getId(),
                        a.getUrl(),
                        a.getOriginalName()
                ))
                .toList();

        return new PostDetailResponse(
                p.getId(),
                p.getTitle(),
                p.getContent(),
                p.getAuthorUsername(),
                p.getCountry(),
                p.getCategory(),
                p.getLanguage(),
                p.getIsForeigner(),
                p.getPersona(),
                p.getGroup(),          // ⭐ group 추가
                attachmentDtos
        );
    }

    // 생성: Principal(username) 사용
    public PostResponse create(PostRequest req, String username) {
        if (username == null || username.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 필요");
        }

        // username → User 엔티티 조회
        User user = userRepository.findByUsername(username)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.UNAUTHORIZED, "존재하지 않는 사용자입니다."));

        // 라벨/코드 정규화
        String normalizedCategory = normalizeCategory(req.getCategory());
        String normalizedLanguage = normalizeLanguage(req.getLanguage());
        String normalizedPersona  = normalizePersona(req.getPersona());

        // 기본 필드 생성자 사용
        Post p = new Post(
                username,
                req.getTitle(),
                req.getContent(),
                req.getCountry(),
                normalizedCategory
        );

        // 메타데이터 매핑
        p.setLanguage(normalizedLanguage);
        p.setIsForeigner(req.getIsForeigner());
        p.setPersona(normalizedPersona);
        p.setGroup(req.getGroup());   // ⭐ group 세팅

        // author_id(FK) 채우기
        p.setAuthor(user);

        Post saved = repo.save(p);
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

        // 라벨/코드 정규화
        String normalizedCategory = normalizeCategory(req.getCategory());
        String normalizedLanguage = normalizeLanguage(req.getLanguage());
        String normalizedPersona  = normalizePersona(req.getPersona());

        p.setTitle(req.getTitle());
        p.setContent(req.getContent());
        p.setCountry(req.getCountry());
        p.setCategory(normalizedCategory);

        p.setLanguage(normalizedLanguage);
        p.setIsForeigner(req.getIsForeigner());
        p.setPersona(normalizedPersona);
        p.setGroup(req.getGroup());   // ⭐ group 수정 시 반영

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
                p.getCreatedAt() != null ? p.getCreatedAt().toString() : null,
                // 🔹 확장 필드들
                p.getLanguage(),
                p.getIsForeigner(),
                p.getPersona(),
                p.getGroup()   // ⭐ 응답 DTO에 group 포함
        );
    }

    // ─────────── 라벨/코드 정규화 헬퍼 ───────────

    private String normalizeCategory(String raw) {
        if (raw == null) return null;
        return switch (raw.trim()) {
            case "전체" -> "ALL";
            case "생활" -> "LIFE";
            case "학업" -> "STUDY";
            case "지역" -> "REGION";
            case "안전" -> "SAFETY";
            case "취업" -> "JOB";
            default -> raw;   // 이미 코드값이면 그대로 사용
        };
    }

    private String normalizeLanguage(String raw) {
        if (raw == null || raw.trim().isEmpty()) return null;
        String s = raw.trim();

        // 이미 코드면 그대로
        switch (s.toLowerCase()) {
            case "ko", "en", "ja", "ms", "fr", "de", "all" -> {
                return s.toLowerCase();
            }
        }

        // 라벨 → 코드
        return switch (s) {
            case "한국어" -> "ko";
            case "영어" -> "en";
            case "일본어" -> "ja";
            case "말레이어" -> "ms";
            case "프랑스어" -> "fr";
            case "독일어" -> "de";
            case "전체" -> "all";
            default -> s;
        };
    }

    private String normalizePersona(String raw) {
        if (raw == null || raw.trim().isEmpty()) return null;
        String s = raw.trim();
        return switch (s) {
            case "내국인" -> "LOCAL";
            case "외국인" -> "FOREIGN";
            case "전체" -> null;
            default -> s;
        };
    }
}
