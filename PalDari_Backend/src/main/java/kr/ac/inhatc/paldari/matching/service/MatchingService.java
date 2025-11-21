package kr.ac.inhatc.paldari.matching.service;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.repository.UserRepository;
import kr.ac.inhatc.paldari.chats.dto.ChatRoomResponse;
import kr.ac.inhatc.paldari.chats.entity.ChatRoom;
import kr.ac.inhatc.paldari.chats.entity.ChatRoomMember;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomMemberRepository;
import kr.ac.inhatc.paldari.chats.repository.ChatRoomRepository;
import kr.ac.inhatc.paldari.matching.dto.MatchingCondition;
import kr.ac.inhatc.paldari.matching.dto.PalSummaryResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.ThreadLocalRandom;

@Slf4j
@Service
@RequiredArgsConstructor
public class MatchingService {

    private final UserRepository userRepository;
    private final ChatRoomRepository chatRoomRepository;
    private final ChatRoomMemberRepository chatRoomMemberRepository;

    /**
     * 매칭 후보 리스트
     * - currentUserId: 나(Seeker)
     * - condition: 매칭 화면에서 사용자가 선택한 조건들
     */
    public List<PalSummaryResponse> findMatchingCandidates(
            Long currentUserId,
            MatchingCondition condition
    ) {
        // 1) 팔 후보 전체 로딩 (나 제외 + allowMatching 등은 쿼리에서 처리)
        List<User> all = userRepository.findAllPalsForUser(currentUserId);

        // 2) 조건 값 정리 ("전체"/"무관"/"ALL"은 null 로)
        String nationality = normalizeFilter(condition.nationality());
        String category    = normalizeFilter(condition.category());
        String region      = normalizeFilter(condition.region());   // 활동 지역
        String language    = normalizeFilter(condition.language());
        String gender      = normalizeGender(condition.gender());
        // Integer minAge  = condition.minAge();
        // Integer maxAge  = condition.maxAge();

        boolean hasAnyCondition =
                nationality != null ||
                        category != null ||
                        region != null ||
                        language != null ||
                        gender != null;
        // || minAge != null || maxAge != null;  // 나이 필터 연결 시 포함

        // 🔹 아무 조건도 없으면 점수 계산 없이 전체 반환
        if (!hasAnyCondition) {
            log.info("Matching candidates for {} with no conditions -> {} users",
                    currentUserId, all.size());
            return all.stream()
                    .map(PalSummaryResponse::from)
                    .toList();
        }

        // 내부용: 점수 + 유저 묶음
        class ScoredUser {
            final User user;
            final int score;

            ScoredUser(User user, int score) {
                this.user = user;
                this.score = score;
            }
        }

        List<ScoredUser> scored = new ArrayList<>();

        for (User u : all) {
            int score = 0;

            // --- ① 국적 (다중 국적: 하나라도 일치하면 +3) ---
            if (nationality != null &&
                    u.getCountries() != null &&
                    !u.getCountries().isEmpty()) {

                boolean hasNationality = u.getCountries().stream()
                        .map(this::trimOrNull)
                        .filter(Objects::nonNull)
                        .anyMatch(c -> c.equalsIgnoreCase(nationality));

                if (hasNationality) {
                    score += 3; // 국적 가중치
                }
            }

            // --- ② 카테고리 (Tag 로 매칭) ---
            if (category != null && u.getTags() != null && !u.getTags().isEmpty()) {
                boolean hasCategory = u.getTags().stream()
                        .map(t -> trimOrNull(t.getTag()))
                        .filter(Objects::nonNull)
                        .anyMatch(tag -> tag.equalsIgnoreCase(category));

                if (hasCategory) {
                    score += 2;
                }
            }

            // --- ③ 활동 지역 (Regions 컬렉션) ---
            if (region != null && u.getRegions() != null && !u.getRegions().isEmpty()) {
                boolean hasRegion = u.getRegions().stream()
                        .map(r -> trimOrNull(r.getRegion()))
                        .filter(Objects::nonNull)
                        .anyMatch(r -> r.equalsIgnoreCase(region));

                if (hasRegion) {
                    score += 2;
                }
            }

            // --- ④ 언어 ---
            if (language != null && u.getLanguage() != null) {
                String userLang = trimOrNull(u.getLanguage());
                if (userLang != null && userLang.equalsIgnoreCase(language)) {
                    score += 2;
                }
            }

            // --- ⑤ 성별 ---
            if (gender != null && u.getGender() != null) {
                String userGender = trimOrNull(u.getGender());
                if (userGender != null && userGender.equalsIgnoreCase(gender)) {
                    score += 1;
                }
            }

            // --- ⑥ 나이 범위 (TODO) ---

            // 최소 하나라도 조건이 맞으면 후보로 인정
            if (score > 0) {
                scored.add(new ScoredUser(u, score));
            }
        }

        // 3) 점수 내림차순 정렬
        scored.sort((a, b) -> Integer.compare(b.score, a.score));

        log.info("Matching candidates for {} -> {}/{} users",
                currentUserId, scored.size(), all.size());

        return scored.stream()
                .map(su -> PalSummaryResponse.from(su.user))
                .toList();
    }

    /**
     * 가장 잘 맞는 Pal 1명만 반환 (없으면 Optional.empty())
     */
    public Optional<PalSummaryResponse> findBestMatch(
            Long currentUserId,
            MatchingCondition condition
    ) {
        List<PalSummaryResponse> list = findMatchingCandidates(currentUserId, condition);
        if (list.isEmpty()) {
            return Optional.empty();
        }
        return Optional.of(list.get(0));
    }

    // ===================== 채팅방 생성/조회 =====================

    public ChatRoomResponse createOrGetChatRoom(Long currentUserId, Long targetUserId) {
        // 🔹 currentUserId / targetUserId 가 "DB PK"이거나,
        //    "숫자로 된 username(예: 1113)" 둘 다 처리할 수 있게 보강
        User me = findUserByIdOrNumericUsername(
                currentUserId,
                "내 사용자 정보를 찾을 수 없습니다."
        );
        User target = findUserByIdOrNumericUsername(
                targetUserId,
                "상대 사용자 정보를 찾을 수 없습니다."
        );

        // 1) 이미 둘 사이에 방이 있으면 그거 재사용
        Optional<ChatRoom> existing =
                chatRoomMemberRepository.findDirectRoomBetweenUsers(me.getId(), target.getId());

        if (existing.isPresent()) {
            return ChatRoomResponse.from(existing.get());
        }

        // 2) 없으면 새 방 생성
        // 다중 국적 전체를 ", " 로 연결하여 표시
        String countryText = (target.getCountries() == null || target.getCountries().isEmpty())
                ? ""
                : String.join(", ", target.getCountries());

        ChatRoom room = ChatRoom.builder()
                .name(target.getUsername())
                .subText(countryText + " / " + target.getLivingIn())
                .build();

        chatRoomRepository.save(room);

        // 3) 멤버 2명 저장 (나 / 상대)
        ChatRoomMember myMember = ChatRoomMember.builder()
                .room(room)
                .user(me)
                .build();

        ChatRoomMember targetMember = ChatRoomMember.builder()
                .room(room)
                .user(target)
                .build();

        chatRoomMemberRepository.save(myMember);
        chatRoomMemberRepository.save(targetMember);

        // 4) 응답 DTO로 변환
        return ChatRoomResponse.from(room);
    }

    // 홈 화면 기본 Pal 리스트 (목업 대신 DB 사용)
    public List<PalSummaryResponse> getHomePalList(Long currentUserId) {
        List<User> users = userRepository.findAll();  // ★ 전체 유저

        return users.stream()
                .filter(u -> !u.getId().equals(currentUserId)) // 원하면 나 자신 제외
                .map(PalSummaryResponse::from)
                .toList();
    }

    // 조건 없이 랜덤 매칭용 (이미 쓰고 있던 메서드)
    public PalSummaryResponse pickRandomPal(Long currentUserId) {
        List<User> all = userRepository.findAllPalsForUser(currentUserId)
                .stream()
                // 예: allowMatching = true만 허용
                .filter(u -> u.getSettings() == null || u.getSettings().isAllowMatching())
                .toList();

        if (all.isEmpty()) {
            return null;
        }

        int idx = ThreadLocalRandom.current().nextInt(all.size());
        User chosen = all.get(idx);
        return PalSummaryResponse.from(chosen);
    }

    // ===================== 헬퍼 =====================

    private String trimOrNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    /**
     * "전체", "무관", "ALL" 등은 필터 미적용으로 간주
     */
    private String normalizeFilter(String s) {
        String v = trimOrNull(s);
        if (v == null) return null;
        if ("전체".equals(v) || "무관".equals(v)) return null;
        if ("ALL".equalsIgnoreCase(v)) return null;
        return v;
    }

    private String normalizeGender(String g) {
        // 필요하면 여기서 "남", "여" → "남성", "여성" 매핑도 가능
        return normalizeFilter(g);
    }

    /**
     * id 로 먼저 찾고, 없으면 "숫자 username" 으로 한 번 더 찾는 헬퍼
     * - currentUserId 가 3 (PK) 여도 동작
     * - currentUserId 가 1113 (username) 여도 동작
     */
    private User findUserByIdOrNumericUsername(Long value, String errorMessage) {
        if (value == null) {
            throw new IllegalArgumentException(errorMessage);
        }

        // 1) 우선 PK(id) 기준으로 시도
        Optional<User> byId = userRepository.findById(value);
        if (byId.isPresent()) {
            return byId.get();
        }

        // 2) 없으면 "value를 문자열로 본 username" 기준으로 시도
        String username = String.valueOf(value);
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException(errorMessage));
    }
}
