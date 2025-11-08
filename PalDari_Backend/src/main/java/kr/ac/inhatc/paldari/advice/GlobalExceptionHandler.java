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
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
import org.springframework.web.util.NestedServletException;

import java.util.Map;

@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // 1) ResponseStatusException (서비스에서 던진 경우)
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String,Object>> handleResponseStatusException(ResponseStatusException ex, WebRequest req) {
        log.info("Handled ResponseStatusException: {} / status={}", ex.getMessage(), ex.getStatusCode().value());
        Map<String,Object> body = Map.of(
                "message", ex.getReason() == null ? ex.getMessage() : ex.getReason(),
                "status", ex.getStatusCode().value()
        );
        return ResponseEntity.status(ex.getStatusCode()).body(body);
    }

    // 2) NestedServletException 언랩핑 (원인에 ResponseStatusException이 있으면 그 상태 사용)
    @ExceptionHandler(NestedServletException.class)
    public ResponseEntity<Map<String,Object>> handleNestedServletException(NestedServletException ex) {
        Throwable cause = ex.getCause();
        if (cause instanceof ResponseStatusException rse) {
            log.info("Unwrapped ResponseStatusException from NestedServletException: {}", rse.getMessage());
            Map<String,Object> body = Map.of(
                    "message", rse.getReason() == null ? rse.getMessage() : rse.getReason(),
                    "status", rse.getStatusCode().value()
            );
            return ResponseEntity.status(rse.getStatusCode()).body(body);
        }
        return handleFallbackException(ex);
    }

    // 3) 타입 불일치 등
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<Map<String,Object>> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        log.warn("Type mismatch: {}", ex.getMessage());
        Map<String,Object> body = Map.of(
                "message", "Type mismatch: " + ex.getMessage(),
                "status", HttpStatus.BAD_REQUEST.value()
        );
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    // 4) Fallback
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String,Object>> handleFallbackException(Exception ex) {
        log.error("Unhandled exception: ", ex);
        Map<String,Object> body = Map.of(
                "message", ex.getMessage(),
                "status", HttpStatus.INTERNAL_SERVER_ERROR.value()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }
}
