package kr.ac.inhatc.paldari.translate.controller;

import kr.ac.inhatc.paldari.translate.service.MockTranslationService;
import kr.ac.inhatc.paldari.translate.service.PapagoTranslationService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

@RestController
@RequestMapping("/api/translate/test")
@RequiredArgsConstructor
public class TranslationTestController {

    private final PapagoTranslationService papagoTranslationService;

    @GetMapping("/papago-no-cache")
    public Map<String, Object> papagoNoCache(
            @RequestParam String sourceLang,
            @RequestParam String targetLang,
            @RequestParam String text
    ) {
        long start = System.currentTimeMillis();

        String result = papagoTranslationService.translate(sourceLang, targetLang, text);

        long end = System.currentTimeMillis();

        Map<String, Object> response = new HashMap<>();
        response.put("mode", "papago-no-cache");
        response.put("sourceLang", sourceLang);
        response.put("targetLang", targetLang);
        response.put("text", text);
        response.put("result", result);
        response.put("responseTimeMs", end - start);
        response.put("apiCallCount", papagoTranslationService.getApiCallCount());

        return response;
    }

    @GetMapping("/papago-redis-cache")
    public Map<String, Object> papagoRedisCache(
            @RequestParam String sourceLang,
            @RequestParam String targetLang,
            @RequestParam String text
    ) {
        long start = System.currentTimeMillis();

        String result = papagoTranslationService.translateWithCache(sourceLang, targetLang, text);

        long end = System.currentTimeMillis();

        Map<String, Object> response = new HashMap<>();
        response.put("mode", "papago-redis-cache");
        response.put("sourceLang", sourceLang);
        response.put("targetLang", targetLang);
        response.put("text", text);
        response.put("result", result);
        response.put("responseTimeMs", end - start);
        response.put("apiCallCount", papagoTranslationService.getApiCallCount());
        response.put("cacheHitCount", papagoTranslationService.getCacheHitCount());
        response.put("cacheMissCount", papagoTranslationService.getCacheMissCount());

        return response;
    }

    @GetMapping("/papago-stats")
    public Map<String, Object> papagoStats() {
        Map<String, Object> response = new HashMap<>();
        response.put("apiCallCount", papagoTranslationService.getApiCallCount());
        response.put("cacheHitCount", papagoTranslationService.getCacheHitCount());
        response.put("cacheMissCount", papagoTranslationService.getCacheMissCount());
        return response;
    }

    @PostMapping("/papago-reset")
    public Map<String, Object> papagoReset() {
        papagoTranslationService.resetStats();
        papagoTranslationService.clearPapagoCache();

        Map<String, Object> response = new HashMap<>();
        response.put("message", "papago test reset complete");
        response.put("apiCallCount", papagoTranslationService.getApiCallCount());
        response.put("cacheHitCount", papagoTranslationService.getCacheHitCount());
        response.put("cacheMissCount", papagoTranslationService.getCacheMissCount());

        return response;
    }
}
