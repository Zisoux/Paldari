package kr.ac.inhatc.paldari.translate.dto;

import lombok.Data;

@Data
public class PapagoTextResponse {
    private Message message;

    @Data
    public static class Message {
        private Result result;
    }

    @Data
    public static class Result {
        private String srcLangType;
        private String tarLangType;
        private String translatedText;
    }
}

