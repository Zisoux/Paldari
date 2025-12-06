package kr.ac.inhatc.paldari.translate.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class PapagoLanguageDetectionService {

    private final WebClient papagoWebClient;

    @Value("${papago.detect-path:/langs/v1/dect}")
    private String detectPath;

    public String detectLanguage(String text) {
        try {
            Map<String, Object> res = papagoWebClient.post()
                    .uri(detectPath)
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(BodyInserters.fromFormData("query", text))
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();

            if (res == null || !res.containsKey("langCode")) {
                log.error("언어 감지 응답 비정상: {}", res);
                throw new IllegalStateException("언어 감지 응답이 비정상입니다.");
            }

            return (String) res.get("langCode");
        } catch (WebClientResponseException e) {
            log.error("Papago 언어 감지 API 오류 - status: {}, body: {}",
                    e.getRawStatusCode(), e.getResponseBodyAsString());
            throw new IllegalStateException("Papago 언어 감지 호출 중 오류가 발생했습니다.", e);
        } catch (Exception e) {
            log.error("Papago 언어 감지 호출 중 예외 발생", e);
            throw new IllegalStateException("Papago 언어 감지 호출 중 예외가 발생했습니다.", e);
        }
    }
}
