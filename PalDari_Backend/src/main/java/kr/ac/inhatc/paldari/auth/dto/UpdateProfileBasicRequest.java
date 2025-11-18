package kr.ac.inhatc.paldari.auth.dto;

import lombok.Data;

import java.util.List;

/**
 * PATCH 부분수정: null이면 해당 필드는 변경하지 않음
 *
 * - gender       : 성별 코드 (예: "MALE", "FEMALE", "OTHER")
 * - birthdate    : "yyyy-MM-dd"
 * - country      : 거주/출신 국가 코드 또는 라벨
 * - livingIn     : 현재 거주지 (자유 문자열)
 * - language     : 대표 언어(단일) — 기존 필드 (필요시 계속 사용)
 * - languages    : 구사 언어 리스트 (예: ["ko", "en", "ja"])
 * - introduction : 자기소개
 * - tags         : 태그 코드 리스트 (예: ["LIFE", "STUDY"])
 * - regions      : 지역 라벨 리스트 (예: ["Seoul", "Paris"])
 */
@Data
public class UpdateProfileBasicRequest {

    private String gender;
    private String birthdate;    // "yyyy-MM-dd"
    private String country;
    private String livingIn;

    // ✅ 기존 단일 언어(대표 언어) 필드 – 이미 쓰고 있다면 계속 사용 가능
    private String language;

    // ✅ 추가: 복수 구사 언어 리스트
    // null  이면 "언어는 건드리지 않음"
    // []    이면 "모두 삭제"
    // ["ko","en"] 등으로 들어옴
    private List<String> languages;

    private String introduction;

    // 🔹 태그 / 지역도 프로필 기본정보에서 한 번에 수정 가능
    // null이면 “태그/지역은 건드리지 않음”
    // 빈 리스트([])면 “모두 삭제”
    private List<String> tags;      // 태그 코드 리스트 (예: ["LIFE", "STUDY"])
    private List<String> regions;   // 지역 라벨 리스트 (예: ["Seoul", "Paris"])
}
