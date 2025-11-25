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

import java.util.*;
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
// 👉 국적/언어/성별/카테고리는 전용 normalizer 사용
        String nationality = normalizeNationality(condition.nationality());
        String category    = normalizeCategory(condition.category());
        String region      = normalizeFilter(condition.region());   // 활동 지역
        String language    = normalizeLanguage(condition.language());
        String gender      = normalizeGender(condition.gender());

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
            boolean matched = true; // ⭐ 선택된 모든 조건을 만족해야 true

            // --- ① 국적 (다중 국적: 하나라도 일치하면 +3) ---
            if (nationality != null) {
                boolean hasNationality = u.getCountries() != null
                        && !u.getCountries().isEmpty()
                        && u.getCountries().stream()
                        .map(this::trimOrNull)
                        // DB에 저장된 country 값도 코드/라벨 통일
                        .map(this::normalizeNationality)
                        .filter(Objects::nonNull)
                        .anyMatch(c -> c.equalsIgnoreCase(nationality));

                if (!hasNationality) {
                    matched = false;
                } else {
                    score += 3; // 국적 가중치
                }
            }

            if (!matched) continue;

            // --- ② 카테고리 (Tag 로 매칭) ---
            if (category != null) {
                boolean hasCategory = u.getTags() != null
                        && !u.getTags().isEmpty()
                        && u.getTags().stream()
                        .map(t -> trimOrNull(t.getTag()))
                        // DB에 저장된 코드(LIFE/…/JOB)를 기준으로 통일
                        .map(this::normalizeCategory)
                        .filter(Objects::nonNull)
                        .anyMatch(tag -> tag.equalsIgnoreCase(category));

                if (!hasCategory) {
                    matched = false;
                } else {
                    score += 2;
                }
            }


            if (!matched) continue;

            // --- ③ 활동 지역 (Regions 컬렉션) ---
            if (region != null) {
                boolean hasRegion = u.getRegions() != null
                        && !u.getRegions().isEmpty()
                        && u.getRegions().stream()
                        .map(r -> trimOrNull(r.getRegion()))
                        .filter(Objects::nonNull)
                        .anyMatch(r -> r.equalsIgnoreCase(region));

                if (!hasRegion) {
                    matched = false;
                } else {
                    score += 2;
                }
            }

            if (!matched) continue;

            // --- ④ 언어 ---
            if (language != null) {
                String langFilter = language; // 위에서 이미 normalizeLanguage 로 정규화된 값

                String langRaw = u.getLanguage();
                List<String> userLangs = List.of();

                if (langRaw != null && !langRaw.trim().isEmpty()) {
                    userLangs = Arrays.stream(langRaw.split("\\s*,\\s*"))  // "ko,en,ja" → ["ko","en","ja"]
                            .map(this::normalizeLanguage)                  // 각각 ko/en/ja 코드로 정규화
                            .filter(Objects::nonNull)
                            .toList();
                }

                boolean hasLang = userLangs.stream()
                        .anyMatch(l -> l.equalsIgnoreCase(langFilter));

                if (!hasLang) {
                    matched = false;
                } else {
                    score += 2;
                }
            }


            if (!matched) continue;

            // --- ⑤ 성별 ---
            if (gender != null) {
                // DB 값(u.getGender())도 코드로 정규화해서 비교
                String userGender = normalizeGender(u.getGender());
                if (userGender == null || !userGender.equalsIgnoreCase(gender)) {
                    matched = false;
                } else {
                    score += 1;
                }
            }


            if (!matched) continue;

            // --- ⑥ 나이 범위 (TODO) ---
            // ※ 아직 구현 X. 기존 주석만 유지.

            // ⭐ 여기까지 살아남은 유저만 후보로 인정
            scored.add(new ScoredUser(u, score));
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
        // "#서울", "#생활" 같이 앞에 # 붙어있으면 제거
        if (t.startsWith("#")) {
            t = t.substring(1).trim();
        }
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

    /**
     * 카테고리 정규화
     * - Flutter: "생활", "학업", "지역", "안전", "취업"
     * - DB: "LIFE", "STUDY", "REGION", "SAFETY", "JOB"
     */
    private String normalizeCategory(String s) {
        String v = normalizeFilter(s);
        if (v == null) return null;

        String upper = v.toUpperCase();

        return switch (upper) {
            case "LIFE", "생활"   -> "LIFE";
            case "STUDY", "학업"  -> "STUDY";
            case "REGION", "지역" -> "REGION";
            case "JOB", "취업"    -> "JOB";
            case "SAFETY", "안전" -> "SAFETY";
            default -> v; // 모르는 값은 그대로
        };
    }


    /**
     * 국적 정규화
     * - Flutter 쪽에서 "한국", "대한민국" 같이 라벨을 보내도,
     * - DB에는 "KR" 코드가 있어도 서로 맞출 수 있게 통일
     */
    private String normalizeNationality(String s) {
        String v = normalizeFilter(s);
        if (v == null) return null;

        String upper = v.toUpperCase();

        return switch (upper) {
            // 한국
            case "KR", "KOREA", "SOUTH KOREA" -> "KR";
            case "대한민국", "한국" -> "KR";

            // 일본
            case "JP", "JAPAN" -> "JP";
            case "일본" -> "JP";

            // 중국
            case "CN", "CHINA" -> "CN";
            case "중국" -> "CN";

            // 말레이시아
            case "MY", "MALAYSIA" -> "MY";
            case "말레이시아" -> "MY";

            // 미국
            case "US", "USA", "UNITED STATES" -> "US";
            case "미국" -> "US";

            // 캐나다
            case "CA", "CANADA" -> "CA";
            case "캐나다" -> "CA";

            // 영국
            case "GB", "UK", "UNITED KINGDOM", "GREAT BRITAIN" -> "GB";
            case "영국" -> "GB";

            // 독일
            case "DE", "GERMANY" -> "DE";
            case "독일" -> "DE";

            // 프랑스
            case "FR", "FRANCE" -> "FR";
            case "프랑스" -> "FR";

            default -> v; // 모르는 값은 그대로 비교
        };
    }

    /**
     * 언어 정규화
     * - "한국어"/"Korean"/"ko"        → "ko"
     * - "영어"/"English (US)" 등 전부 → "en"
     * - "Bahasa Melayu"/"ms"         → "ms"
     * - "Deutsch"/"독일어"/"de"      → "de"
     * - "Français"/"프랑스어"/"fr"   → "fr"
     */
    private String normalizeLanguage(String s) {
        String v = normalizeFilter(s);
        if (v == null) return null;

        String lower = v.toLowerCase();

        return switch (lower) {
            // 한국어
            case "ko", "korean", "한국어" -> "ko";

            // 영어 (모든 변형을 en 으로 통일)
            case "en", "english", "영어",
                 "english (us)", "english (uk)", "english (ca)", "english (au)" -> "en";

            // 일본어
            case "ja", "japanese", "일본어", "日本語" -> "ja";

            // 중국어
            case "zh", "chinese", "중국어" -> "zh";

            // 말레이어
            case "ms", "malay", "bahasa melayu", "말레이어" -> "ms";

            // 독일어
            case "de", "german", "deutsch", "독일어" -> "de";

            // 프랑스어
            case "fr", "french", "français", "프랑스어" -> "fr";

            default -> v;
        };
    }


    /**
     * 성별 정규화
     * - "무관", "전체" → null (필터 X)
     * - "남", "남성", "male", "M", "MALE"  → "MALE"
     * - "여", "여성", "female", "F", "FEMALE" → "FEMALE"
     * - "OTHER", "기타" → "OTHER"
     *   (DB에는 "MALE"/"FEMALE"/"OTHER" 코드로 저장된다고 가정)
     */
    private String normalizeGender(String g) {
        String v = trimOrNull(g);
        if (v == null) return null;

        // 무관 / 전체는 필터 적용 안 함
        if ("전체".equals(v) || "무관".equals(v) || "ALL".equalsIgnoreCase(v)) {
            return null;
        }

        String lower = v.toLowerCase();

        // 남성 계열
        if (lower.equals("남") || lower.equals("남성") ||
                lower.equals("male") || lower.equals("m")) {
            return "MALE";
        }

        // 여성 계열
        if (lower.equals("여") || lower.equals("여성") ||
                lower.equals("female") || lower.equals("f")) {
            return "FEMALE";
        }

        // 기타
        if (lower.equals("other") || lower.equals("기타")) {
            return "OTHER";
        }

        // 이미 코드로 저장된 경우
        if ("MALE".equalsIgnoreCase(v)) return "MALE";
        if ("FEMALE".equalsIgnoreCase(v)) return "FEMALE";
        if ("OTHER".equalsIgnoreCase(v)) return "OTHER";

        // 그 외는 그대로
        return v;
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
