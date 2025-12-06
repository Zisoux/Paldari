package kr.ac.inhatc.paldari.auth.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailAuthenticationException;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Service
public class MailService {

    private static final Logger log = LoggerFactory.getLogger(MailService.class);

    private final ObjectProvider<JavaMailSender> senderProvider;

    @Value("${spring.mail.username:}")
    private String defaultFrom;

    @Value("${app.url:http://localhost:8080}")
    private String appBaseUrl;

    @Value("${app.mail.enabled:true}")
    private boolean mailEnabled;

    public MailService(ObjectProvider<JavaMailSender> senderProvider) {
        this.senderProvider = senderProvider;
    }

    /** 이메일 인증 메일 발송 */
    public void sendVerificationEmail(String to, String token) {
        String base = trimTrailingSlash(appBaseUrl);
        String verifyUrl = base + "/api/auth/verify?token=" + url(token);

        String subject = "[Pal다리] 이메일 인증 안내";
        String text = "Click the link to verify your email:\n" + verifyUrl + "\n\nThis link expires in 24 hours.";
        String html = """
            <div style="font-family:system-ui,'Noto Sans KR',sans-serif;line-height:1.6">
              <h2>이메일 인증</h2>
              <p>아래 버튼을 눌러 이메일을 인증해 주세요. (24시간 유효)</p>
              <p><a href="%s" style="display:inline-block;padding:12px 16px;background:#F29D52;color:#fff;text-decoration:none;border-radius:8px">이메일 인증하기</a></p>
              <p style="color:#666;font-size:12px">버튼이 보이지 않으면 아래 링크를 복사해 브라우저에 붙여넣기:<br>%s</p>
            </div>
            """.formatted(verifyUrl, verifyUrl);

        sendMail(to, subject, text, html);
    }

    /** 비밀번호 재설정용 인증코드 메일 발송 */
    public void sendPasswordResetCode(String to, String code, int ttlMinutes) {
        String subject = "[Pal다리] 비밀번호 재설정 인증 코드";
        String text = "인증 코드는 " + code + " 입니다.\n이 코드는 " + ttlMinutes + "분 동안 유효합니다.";
        String html = """
            <div style="font-family:system-ui,'Noto Sans KR',sans-serif;line-height:1.6">
              <h2>비밀번호 재설정</h2>
              <p>인증 코드는 <b style="font-size:18px">%s</b> 입니다.</p>
              <p style="color:#666">이 코드는 %d분 동안 유효하며, 한 번만 사용할 수 있습니다.</p>
            </div>
            """.formatted(code, ttlMinutes);

        sendMail(to, subject, text, html);
    }

    /* ---------------- 내부 구현 ---------------- */

    private void sendMail(String to, String subject, String textBody, String htmlBody) {
        if (!mailEnabled) {
            log.warn("[DEV] 메일 전송 비활성화. to={}, subject={}\nTEXT:\n{}\n\nHTML:\n{}", to, subject, textBody, htmlBody);
            return;
        }

        JavaMailSender mailSenderBean = senderProvider.getIfAvailable();
        if (mailSenderBean == null) {
            log.warn("[DEV] JavaMailSender 미구성. 실제 메일 미발송. subject={}, to={}", subject, to);
            return;
        }

        try {
            // HTML + PLAIN alternative
            MimeMessage msg = mailSenderBean.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(msg, true, "UTF-8");
            if (defaultFrom != null && !defaultFrom.isBlank()) {
                helper.setFrom(defaultFrom);
            }
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(textBody, htmlBody); // (plain, html)
            mailSenderBean.send(msg);
            log.info("Mail sent to {} (subject: {})", to, subject);

        } catch (MessagingException me) {
            // 폴백: 텍스트 메일만 전송 시도 (동일 bean 재사용, 재선언 금지)
            try {
                SimpleMailMessage sm = new SimpleMailMessage();
                if (defaultFrom != null && !defaultFrom.isBlank()) {
                    sm.setFrom(defaultFrom);
                }
                sm.setTo(to);
                sm.setSubject(subject);
                sm.setText(textBody);
                mailSenderBean.send(sm);
                log.info("Fallback(text) mail sent to {} (subject: {})", to, subject);
            } catch (MailException e) {
                log.error("메일 전송 실패(fallback): {}", e.getMessage(), e);
                throw e;
            }
        } catch (MailAuthenticationException e) {
            log.error("SMTP 인증 실패: {}", e.getMessage(), e);
            throw e;
        } catch (MailException e) {
            log.error("메일 전송 실패: {}", e.getMessage(), e);
            throw e;
        }
    }

    private String trimTrailingSlash(String s) {
        return (s != null && s.endsWith("/")) ? s.substring(0, s.length() - 1) : s;
    }

    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}
