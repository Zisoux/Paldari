package kr.ac.inhatc.paldari.auth.dto;

import lombok.Data;

/** PATCH 부분수정: null이면 해당 필드는 변경하지 않음 */
@Data
public class UpdateProfileBasicRequest {
    private String gender;
    private String birthdate;   // "yyyy-MM-dd"
    private String country;
    private String livingIn;
    private String language;
    private String introduction;
}
