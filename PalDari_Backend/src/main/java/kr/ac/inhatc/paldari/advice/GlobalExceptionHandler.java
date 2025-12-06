package kr.ac.inhatc.paldari.advice;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
import org.springframework.web.util.NestedServletException;

import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /* ---------- 공통 유틸: 절대 Map.of() 쓰지 말 것 (null 넣으면 NPE) ---------- */

    private Map<String, Object> respBody(int status, String message) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("status", status);
        body.put("message", message == null ? "" : message);
        return body;
    }

    private String safeRseMessage(ResponseStatusException ex) {
        // reason 우선, 없으면 getMessage()
        String reason = ex.getReason();
        if (reason != null && !reason.isBlank()) return reason;
        String msg = ex.getMessage();
        return msg == null ? "" : msg;
    }

    /* ---------- 1) 서비스/컨트롤러에서 던진 ResponseStatusException ---------- */

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handleResponseStatusException(ResponseStatusException ex) {
        int code = ex.getStatusCode().value();
        String message = safeRseMessage(ex);
        log.info("Handled ResponseStatusException: status={}, message={}", code, message);
        return ResponseEntity.status(ex.getStatusCode()).body(respBody(code, message));
    }

    /* ---------- 2) NestedServletException 언랩핑 ---------- */

    @ExceptionHandler(NestedServletException.class)
    public ResponseEntity<Map<String, Object>> handleNestedServletException(NestedServletException ex) {
        Throwable cause = ex.getCause();
        if (cause instanceof ResponseStatusException rse) {
            int code = rse.getStatusCode().value();
            String message = safeRseMessage(rse);
            log.info("Unwrapped ResponseStatusException from NestedServletException: status={}, message={}", code, message);
            return ResponseEntity.status(rse.getStatusCode()).body(respBody(code, message));
        }
        // 그 외는 fallback으로 위임
        return handleFallbackException(ex);
    }

    /* ---------- 3) 타입 불일치 (예: path/query param 바인딩 오류) ---------- */

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<Map<String, Object>> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        int code = HttpStatus.BAD_REQUEST.value();
        String message = "Type mismatch: " + (ex.getMessage() == null ? "" : ex.getMessage());
        log.warn("Type mismatch: {}", message);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(respBody(code, message));
    }

    /* ---------- 4) IllegalArgumentException (도메인 검증 실패 등) ---------- */

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex) {
        int code = HttpStatus.BAD_REQUEST.value();
        String message = ex.getMessage();
        log.warn("IllegalArgumentException: {}", message);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(respBody(code, message));
    }

    /* ---------- 5) Fallback (그 외 모든 예외) ---------- */

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleFallbackException(Exception ex) {
        int code = HttpStatus.INTERNAL_SERVER_ERROR.value();
        String message = ex.getMessage();
        log.error("Unhandled exception: ", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(respBody(code, message));
    }
}
