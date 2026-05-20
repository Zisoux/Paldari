package kr.ac.inhatc.paldari.translate.service;

import org.springframework.stereotype.Service;

import java.util.concurrent.atomic.AtomicInteger;

@Service
public class MockTranslationService {

    private final AtomicInteger apiCallCount = new AtomicInteger(0);

    public String translate(String sourceLang, String targetLang, String text) {
        apiCallCount.incrementAndGet();
        try {
            Thread.sleep(1000); // 외부 번역 API 지연 시간 모사
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        return "[MOCK_TRANSLATED] " + sourceLang + "->" + targetLang + ": " + text;
    }

    public int getApiCallCount() {
        return apiCallCount.get();
    }

    public void resetApiCallCount() {
        apiCallCount.set(0);
    }
}