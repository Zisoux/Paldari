package kr.ac.inhatc.paldari.auth.dto;

import kr.ac.inhatc.paldari.rating.web.dto.RatingSummaryDto;
import lombok.Data;
import java.util.List;

/**
 * 공개 상대 프로필 + 평점 요약 DTO
 */
@Data
public class ProfileDetailDto {

    // =======================
    //   사용자 고유 정보
    // =======================
    private Long userId;
    private String nickname;

    // =======================
    //   기본 프로필 정보
    // =======================
    private String gender;
    private String birthdate;
    private String country;
    private String livingIn;
    private List<String> languages;
    private String introduction;

    // =======================
    //   확장 정보
    // =======================
    private List<String> tags;
    private List<String> regions;

    // =======================
    //   평점 정보
    // =======================
    private Double averageScore;   // RatingSummaryDto.average
    private Long totalCount;       // RatingSummaryDto.totalCount

    // =======================
    //   생성자
    // =======================
    public ProfileDetailDto(ProfileBasicDto profile, RatingSummaryDto rating) {

        this.gender = profile.getGender();
        this.birthdate = profile.getBirthdate();
        this.country = profile.getCountry();
        this.livingIn = profile.getLivingIn();
        this.languages = profile.getLanguages();

        this.introduction = profile.getIntroduction();
        this.tags = profile.getTags();
        this.regions = profile.getRegions();

        if (rating != null) {
            this.averageScore = rating.getAverage();      // ★ 수정됨
            this.totalCount = rating.getTotalCount();     // ★ 수정됨
        }
    }

    public ProfileDetailDto() {}
}
