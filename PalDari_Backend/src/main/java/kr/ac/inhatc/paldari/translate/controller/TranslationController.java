package kr.ac.inhatc.paldari.translate.controller;

import kr.ac.inhatc.paldari.translate.dto.*;
import kr.ac.inhatc.paldari.translate.service.PapagoLanguageDetectionService;
import kr.ac.inhatc.paldari.translate.service.PapagoTranslationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/translate")
@RequiredArgsConstructor
public class TranslationController {

    private final PapagoTranslationService papagoTranslationService;
    private final PapagoLanguageDetectionService papagoLanguageDetectionService; // 🔹 추가

    @PostMapping("/text")
    public TranslateTextResponse translate(@RequestBody TranslateTextRequest req) {
        String translated = papagoTranslationService.translate(
                req.getSourceLang(),
                req.getTargetLang(),
                req.getText()
        );
        return new TranslateTextResponse(translated);
    }

    // 🔹 언어 감지 엔드포인트
    @PostMapping("/detect")
    public DetectLanguageResponse detect(@RequestBody DetectLanguageRequest req) {
        String langCode = papagoLanguageDetectionService.detectLanguage(req.getText());
        return new DetectLanguageResponse(langCode);
    }
}
