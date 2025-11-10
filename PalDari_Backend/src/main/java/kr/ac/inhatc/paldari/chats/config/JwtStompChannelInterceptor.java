package kr.ac.inhatc.paldari.chats.config;

import kr.ac.inhatc.paldari.auth.jwt.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.MessagingException;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

import java.util.Collections;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtStompChannelInterceptor implements ChannelInterceptor {

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor =
                MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

        if (accessor == null || accessor.getCommand() == null) {
            return message;
        }

        StompCommand command = accessor.getCommand();

        // CONNECT 시에만 JWT 인증 처리
        if (StompCommand.CONNECT.equals(command)) {
            String authHeader = accessor.getFirstNativeHeader("Authorization");

            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                log.warn("STOMP CONNECT without Authorization header");
                throw new MessagingException("No JWT token in STOMP CONNECT");
            }

            String token = authHeader.substring(7);

            // 🔍 JwtTokenProvider.validate() 사용
            if (!jwtTokenProvider.validate(token)) {
                log.warn("Invalid JWT token in STOMP CONNECT");
                throw new MessagingException("Invalid JWT token");
            }

            // 👤 토큰에서 username 추출
            String username = jwtTokenProvider.getUsername(token);

            // 여기서는 간단히 username만 Authentication에 넣어줌
            // (권한 필요하면 UserDetailsService 통해 다시 조회해서 authorities 채워도 됨)
            Authentication authentication =
                    new UsernamePasswordAuthenticationToken(username, null, Collections.emptyList());

            // STOMP 세션에 사용자 정보 저장 → 이후 Controller에서 Principal로 접근 가능
            accessor.setUser(authentication);

            log.debug("STOMP user authenticated: {}", username);
        }

        return message;
    }
}