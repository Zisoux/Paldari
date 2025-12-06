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

    private String normalizeCountry(String raw) {
        if (raw == null) return null;
        raw = raw.trim();

        return switch (raw) {

            // 🇲🇾 말레이시아
            case "말레이시아", "Malaysia", "MY", "my", "malaysia" -> "말레이시아";

            // 🇰🇷 한국
            case "한국", "대한민국", "Korea", "South Korea", "KR", "kor", "korea" -> "한국";

            // 🇯🇵 일본
            case "일본", "Japan", "JP", "japan" -> "일본";

            // 🇺🇸 미국
            case "미국", "USA", "United States", "US", "america", "us" -> "미국";

            // 🇨🇦 캐나다
            case "캐나다", "Canada", "CA", "canada" -> "캐나다";

            // 🇦🇺 호주
            case "호주", "Australia", "AU", "australia" -> "호주";

            // 🇬🇧 영국
            case "영국", "United Kingdom", "UK", "England", "GB", "uk" -> "영국";

            // 🇩🇪 독일
            case "독일", "Germany", "DE", "germany" -> "독일";

            // 🇫🇷 프랑스
            case "프랑스", "France", "FR", "france" -> "프랑스";

            default -> raw; // 알 수 없는 값은 그대로 반환
        };
    }


    /**
     * 🔹 기존 전체 조회 (필터 없이)
     *   - 다른 곳에서 사용 중일 수 있어 그대로 둠
     */
    @Transactional(Transactional.TxType.SUPPORTS)
    public List<PostResponse> listAll() {
        return repo.findAll(Sort.by(Sort.Direction.DESC, "createdAt"))
                .stream()
                .map(this::toDto)
                .toList();
    }

    /**
     * 🔹 내국인/외국인 필터를 적용한 목록 조회
     *   persona:
     *     - null, "전체", "ALL"  → 전체
     *     - "LOCAL" / "내국인"  → 내국인만
     *     - "FOREIGN" / "외국인" → 외국인만
     */
    @Transactional(Transactional.TxType.SUPPORTS)
    public List<PostResponse> listAll(String persona) {
        String code = normalizePersona(persona); // "내국인"/"외국인"/"전체"/null 처리

        List<Post> posts;
        if (code == null) {
            // 전체 조회
            posts = repo.findAll(Sort.by(Sort.Direction.DESC, "createdAt"));
        } else {
            // persona 코드(LOCAL / FOREIGN)로 필터
            posts = repo.findByPersonaOrderByCreatedAtDesc(code);
        }

        return posts.stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional(Transactional.TxType.SUPPORTS)
    public Page<PostResponse> list(Pageable pageable) {
        return repo.findAll(pageable)
                .map(this::toDto);
    }

    // 🔹 기본 조회 (필요하면 계속 사용)
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
        // 🔸 persona 는 이제 요청값을 그대로 쓰지 않고, 아래에서 자동 계산

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
        p.setGroup(req.getGroup());   // ⭐ group 세팅

        // author_id(FK) 채우기
        p.setAuthor(user);

        // ⭐ 작성자 국적(여러 개) vs 게시글 국가를 비교해서 내/외국인 자동 계산
        applyForeignerPersona(p, user);

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
        // 🔸 persona 는 여기서도 요청값을 사용하지 않고 자동 계산

        p.setTitle(req.getTitle());
        p.setContent(req.getContent());
        p.setCountry(req.getCountry());
        p.setCategory(normalizedCategory);

        p.setLanguage(normalizedLanguage);
        p.setGroup(req.getGroup());   // ⭐ group 수정 시 반영

        // ⭐ author는 이미 p.getAuthor() 에 있으므로 그걸 기준으로 다시 계산
        applyForeignerPersona(p, p.getAuthor());

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

    // ─────────── 내/외국인 & 페르소나 자동 계산 헬퍼 ───────────

    /**
     * 작성자(author)의 다중 국적(countries)과 게시글 country 를 비교해서
     *  - isForeigner: true / false
     *  - persona: "LOCAL" / "FOREIGN"
     * 으로 자동 세팅한다.
     *
     * - author.countries 중 하나라도 post.country 와 같으면 → 내국인(LOCAL)
     * - 전부 다르면 → 외국인(FOREIGN)
     * - 둘 중 하나라도 비어 있으면 (국가 정보를 모르면) null 로 둔다.
     */
    private void applyForeignerPersona(Post post, User author) {
        if (author == null) {
            post.setIsForeigner(null);
            post.setPersona(null);
            return;
        }

        // ⭐ 국가명 정규화 함수 사용
        String postCountry = normalizeCountry(post.getCountry());
        List<String> userCountries = author.getCountries()
                .stream()
                .map(this::normalizeCountry)
                .filter(c -> c != null && !c.isBlank())
                .toList();

        if (postCountry == null || postCountry.isBlank() || userCountries.isEmpty()) {
            post.setIsForeigner(null);
            post.setPersona(null);
            return;
        }

// ⭐ 정규화된 국가끼리 비교
        boolean isLocal = userCountries.contains(postCountry);

        post.setIsForeigner(!isLocal);
        post.setPersona(isLocal ? "LOCAL" : "FOREIGN");

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

    /**
     * 쿼리 파라미터/라벨에서 들어오는 persona 를 코드로 통일
     * - "내국인" / "LOCAL"  -> "LOCAL"
     * - "외국인" / "FOREIGN" -> "FOREIGN"
     * - "전체" / "ALL" / null -> null (필터 안 함)
     */
    private String normalizePersona(String raw) {
        if (raw == null || raw.trim().isEmpty()) return null;
        String s = raw.trim();

        return switch (s) {
            case "내국인", "LOCAL" -> "LOCAL";
            case "외국인", "FOREIGN" -> "FOREIGN";
            case "전체", "ALL" -> null;
            default -> s;
        };
    }
}
