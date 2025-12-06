package kr.ac.inhatc.paldari.translate.service;

import kr.ac.inhatc.paldari.translate.dto.PapagoTextResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

@Slf4j
@Service
@RequiredArgsConstructor
public class PapagoTranslationService {

    private final WebClient papagoWebClient; // PapagoConfig에서 만든 Bean

    @Value("${papago.text-path}")
    private String textPath; // "/nmt/v1/translation"

    /**
     * @param source Papago source 언어 코드 (ko, en, ja, auto ...)
     * @param target Papago target 언어 코드 (ko, en, ja ...)
     * @param text   번역할 문장
     */
    public String translate(String source, String target, String text) {

        // ✅ text 비어 있으면 그냥 반환
        if (text == null || text.isBlank()) {
            return text;
        }

        // ✅ 입력값 정리 (null/빈 문자열 기본값 + trim)
        String src = (source == null || source.isBlank()) ? "auto" : source.trim();
        String tgt = (target == null || target.isBlank()) ? "ko" : target.trim(); // 기본 target은 ko

        // 🔍 실제 Papago로 나가기 전에 로그 남기기 (디버깅용)
        log.info("Papago 요청 준비 → source={}, target={}, textPreview={}",
                src,
                tgt,
                text.length() > 20 ? text.substring(0, 20) + "..." : text
        );

        // ✅ Papago는 source == target이면 N2MT05 에러를 던짐
        //    단, source = auto 인 경우는 허용
        if (!src.equalsIgnoreCase("auto") && src.equalsIgnoreCase(tgt)) {
            log.debug("Papago 호출 스킵: source == target ({}). 원문 그대로 반환.", src);
            return text;
        }

        try {
            PapagoTextResponse response = papagoWebClient.post()
                    .uri(textPath)
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(BodyInserters
                            .fromFormData("source", src)
                            .with("target", tgt)
                            .with("text", text))
                    .retrieve()
                    .bodyToMono(PapagoTextResponse.class)
                    .block(); // 동기 방식으로 받기

            if (response == null ||
                    response.getMessage() == null ||
                    response.getMessage().getResult() == null) {
                log.error("Papago 응답이 비정상입니다. response={}", response);
                throw new IllegalStateException("Papago 응답이 비정상입니다.");
            }

            return response.getMessage().getResult().getTranslatedText();

        } catch (WebClientResponseException e) {
            int status = e.getStatusCode() != null ? e.getStatusCode().value() : -1;
            String body = e.getResponseBodyAsString();
            log.error("Papago API 오류 - status: {}, body: {}", status, body);

            // ✅ Papago가 source==target(N2MT05) 때문에 400을 던진 경우
            //    → 예외 대신 원문 그대로 반환
            if (status == 400 && body != null && body.contains("N2MT05")) {
                log.warn("Papago N2MT05(source와 target 동일) 감지 → 번역 없이 원문 반환");
                return text;
            }

            throw new IllegalStateException("Papago API 통신 중 오류가 발생했습니다.", e);
        } catch (Exception e) {
            log.error("Papago API 호출 중 예외 발생", e);
            throw new IllegalStateException("Papago API 호출 중 예외가 발생했습니다.", e);
        }
    }
}
