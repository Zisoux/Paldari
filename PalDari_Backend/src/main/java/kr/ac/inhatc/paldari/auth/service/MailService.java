package kr.ac.inhatc.paldari.auth.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailAuthenticationException;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Service
public class MailService {

    private static final Logger log = LoggerFactory.getLogger(MailService.class);

    // JavaMailSender를 선택적으로 사용 (개발 중 미구성이어도 앱이 뜨도록)
    private final ObjectProvider<JavaMailSender> senderProvider;

    // 보내는 주소(보통 spring.mail.username과 동일해야 Gmail이 허용)
    @Value("${spring.mail.username:}")
    private String defaultFrom;

    // 베이스 URL (환경별 분리: 로컬/운영)
    @Value("${app.url:http://localhost:8080}")
    private String appBaseUrl;

    // 개발 중 메일 전송 끄기 스위치
    @Value("${app.mail.enabled:true}")
    private boolean mailEnabled;

    public MailService(ObjectProvider<JavaMailSender> senderProvider) {
        this.senderProvider = senderProvider;
    }

    public void sendVerificationEmail(String to, String token) {
        // base URL 정리 + 토큰 인코딩
        String base = appBaseUrl.endsWith("/") ? appBaseUrl.substring(0, appBaseUrl.length() - 1) : appBaseUrl;
        String verifyUrl = base + "/api/auth/verify?token=" + URLEncoder.encode(token, StandardCharsets.UTF_8);

        // 개발 모드: 실제 전송 대신 링크만 로그에 출력
        if (!mailEnabled) {
            log.warn("[DEV] 메일 전송 비활성화. 수신자={}, 인증링크={}", to, verifyUrl);
            return;
        }

        JavaMailSender sender = senderProvider.getIfAvailable();
        if (sender == null) {
            log.warn("[DEV] JavaMailSender 미구성. 실제 메일 미발송. 인증링크={}", verifyUrl);
            return;
        }

        try {
            SimpleMailMessage msg = new SimpleMailMessage();
            if (defaultFrom != null && !defaultFrom.isBlank()) {
                // Gmail 사용 시 From은 spring.mail.username과 동일해야 535(인증거부) 회피
                msg.setFrom(defaultFrom);
            }
            msg.setTo(to);
            msg.setSubject("[YourApp] Please verify your email");
            msg.setText("Click the link to verify your email:\n" + verifyUrl + "\n\nThis link expires in 24 hours.");

            sender.send(msg);
            log.info("Verification mail sent to {}", to);
        } catch (MailAuthenticationException e) {
            // 앱 비밀번호/From 설정 이슈일 가능성 큼
            log.error("SMTP 인증 실패: {} (verifyUrl={})", e.getMessage(), verifyUrl, e);
            throw e;
        } catch (MailException e) {
            log.error("메일 전송 실패: {} (verifyUrl={})", e.getMessage(), verifyUrl, e);
            throw e;
        }
    }
}
