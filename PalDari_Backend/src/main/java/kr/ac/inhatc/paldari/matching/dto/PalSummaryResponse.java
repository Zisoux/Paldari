package kr.ac.inhatc.paldari.matching.dto;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.entity.UserRegion;
import kr.ac.inhatc.paldari.auth.entity.UserSettings;
import kr.ac.inhatc.paldari.auth.entity.UserTag;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class PalSummaryResponse {

    private Long id;
    private String username;
    private String country;
    private String livingIn;
    private String language;
    private String introduction;

    private List<String> regions; // ["#서울", "#말레이시아"]
    private List<String> tags;    // ["#생활", "#학업"]

    private boolean allowMatching;
    private boolean realtimeTranslation;

    public static PalSummaryResponse from(User user) {
        UserSettings s = user.getSettings();

        List<String> regionList = user.getRegions() == null
                ? List.of()
                : user.getRegions().stream()
                .map(UserRegion::getRegion)
                .toList();

        List<String> tagList = user.getTags() == null
                ? List.of()
                : user.getTags().stream()
                .map(UserTag::getTag)
                .toList();

        return PalSummaryResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .country(user.getCountry())
                .livingIn(user.getLivingIn())
                .language(user.getLanguage())
                .introduction(user.getIntroduction())
                .regions(regionList)
                .tags(tagList)
                .allowMatching(s == null || s.isAllowMatching())
                .realtimeTranslation(s != null && s.isRealtimeTranslation())
                .build();
    }
}
