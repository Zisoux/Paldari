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

    public String translate(String source, String target, String text) {
        try {
            PapagoTextResponse response = papagoWebClient.post()
                    .uri(textPath)
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(BodyInserters
                            .fromFormData("source", source)
                            .with("target", target)
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
            // Papago 쪽에서 에러 코드 내려줬을 때
            int status = e.getStatusCode() != null ? e.getStatusCode().value() : -1;
            log.error("Papago API 오류 - status: {}, body: {}", status, e.getResponseBodyAsString());
            throw new IllegalStateException("Papago API 통신 중 오류가 발생했습니다.", e);
        } catch (Exception e) {
            log.error("Papago API 호출 중 예외 발생", e);
            throw new IllegalStateException("Papago API 호출 중 예외가 발생했습니다.", e);
        }
    }
}
