package kr.ac.inhatc.paldari.translate.service;

import kr.ac.inhatc.paldari.translate.dto.PapagoTextResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.time.Duration;
import java.util.concurrent.atomic.AtomicInteger;

@Slf4j
@Service
@RequiredArgsConstructor
public class PapagoTranslationService {

    private final WebClient papagoWebClient; // PapagoConfig에서 만든 Bean
    private final StringRedisTemplate redisTemplate;

    @Value("${papago.text-path}")
    private String textPath; // "/nmt/v1/translation"

    private final AtomicInteger apiCallCount = new AtomicInteger(0);
    private final AtomicInteger cacheHitCount = new AtomicInteger(0);
    private final AtomicInteger cacheMissCount = new AtomicInteger(0);

    /**
     * No Cache 구조
     * 매 요청마다 Papago API를 직접 호출한다.
     *
     * @param source Papago source 언어 코드
     * @param target Papago target 언어 코드
     * @param text   번역할 문장
     */
    public String translate(String source, String target, String text) {
        return callPapagoApi(source, target, text);
    }

    /**
     * Redis Cache 구조
     * 동일한 번역 요청이 Redis에 저장되어 있으면 Papago API를 호출하지 않고 캐시 값을 반환한다.
     */
    public String translateWithCache(String source, String target, String text) {

        if (text == null || text.isBlank()) {
            return text;
        }

        String src = (source == null || source.isBlank()) ? "auto" : source.trim();
        String tgt = (target == null || target.isBlank()) ? "ko" : target.trim();

        String cacheKey = createCacheKey(src, tgt, text);

        String cached = redisTemplate.opsForValue().get(cacheKey);

        if (cached != null) {
            cacheHitCount.incrementAndGet();

            log.info("Papago Redis Cache Hit → key={}", cacheKey);

            return cached;
        }

        cacheMissCount.incrementAndGet();

        log.info("Papago Redis Cache Miss → key={}", cacheKey);

        String translated = callPapagoApi(src, tgt, text);

        redisTemplate.opsForValue().set(
                cacheKey,
                translated,
                Duration.ofMinutes(10)
        );

        return translated;
    }

    /**
     * 실제 Papago API 호출부
     */
    private String callPapagoApi(String source, String target, String text) {

        if (text == null || text.isBlank()) {
            return text;
        }

        String src = (source == null || source.isBlank()) ? "auto" : source.trim();
        String tgt = (target == null || target.isBlank()) ? "ko" : target.trim();

        log.info("Papago 요청 준비 → source={}, target={}, textPreview={}",
                src,
                tgt,
                text.length() > 20 ? text.substring(0, 20) + "..." : text
        );

        if (!src.equalsIgnoreCase("auto") && src.equalsIgnoreCase(tgt)) {
            log.debug("Papago 호출 스킵: source == target ({}). 원문 그대로 반환.", src);
            return text;
        }

        apiCallCount.incrementAndGet();

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
                    .block();

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

    /**
     * Redis Cache Key 생성
     */
    private String createCacheKey(String source, String target, String text) {
        return "papago:" + source + ":" + target + ":" + text;
    }

    public int getApiCallCount() {
        return apiCallCount.get();
    }

    public int getCacheHitCount() {
        return cacheHitCount.get();
    }

    public int getCacheMissCount() {
        return cacheMissCount.get();
    }

    public void resetStats() {
        apiCallCount.set(0);
        cacheHitCount.set(0);
        cacheMissCount.set(0);
    }

    public void clearPapagoCache() {
        redisTemplate.delete(redisTemplate.keys("papago:*"));
    }
}