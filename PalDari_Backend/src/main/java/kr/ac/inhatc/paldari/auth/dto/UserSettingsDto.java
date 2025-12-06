package kr.ac.inhatc.paldari.auth.dto;

import kr.ac.inhatc.paldari.auth.entity.UserSettings;

public record UserSettingsDto(
        boolean allowNotification,
        boolean allowMatching,
        boolean realtimeTranslation
) {
    public static UserSettingsDto from(UserSettings s) {
        return new UserSettingsDto(
                s.isAllowNotification(),
                s.isAllowMatching(),
                s.isRealtimeTranslation()
        );
    }
}