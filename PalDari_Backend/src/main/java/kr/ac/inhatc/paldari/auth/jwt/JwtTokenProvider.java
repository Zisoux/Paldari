package kr.ac.inhatc.paldari.auth.jwt;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Date;

@Component
public class JwtTokenProvider {

    private final Key key;

    // access / refresh 각각 유효기간 설정
    private final long accessTokenValidityMillis;
    private final long refreshTokenValidityMillis;

    public JwtTokenProvider(
            @Value("${security.jwt.secret:replace-this-with-a-very-long-secure-secret-key-please}") String secret,
            // 기본: access 30분
            @Value("${security.jwt.access-validity-millis:1800000}") long accessTokenValidityMillis,
            // 기본: refresh 7일
            @Value("${security.jwt.refresh-validity-millis:604800000}") long refreshTokenValidityMillis
    ) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessTokenValidityMillis = accessTokenValidityMillis;
        this.refreshTokenValidityMillis = refreshTokenValidityMillis;
    }

    // ================== 새 구조 ==================

    /** 액세스 토큰 발급 (API 호출용, 짧은 수명) */
    public String generateAccessToken(String subject) {
        Date now = new Date();
        Date exp = new Date(now.getTime() + accessTokenValidityMillis);

        return Jwts.builder()
                .setSubject(subject)
                .claim("type", "access")
                .setIssuedAt(now)
                .setExpiration(exp)
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    /** 리프레시 토큰 발급 (재발급용, 긴 수명) */
    public String generateRefreshToken(String subject) {
        Date now = new Date();
        Date exp = new Date(now.getTime() + refreshTokenValidityMillis);

        return Jwts.builder()
                .setSubject(subject)
                .claim("type", "refresh")
                .setIssuedAt(now)
                .setExpiration(exp)
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    /** 토큰 유효성 검사 (access / refresh 공통) */
    public boolean validateToken(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    /** sub (email/username) 꺼내기 */
    public String getSubject(String token) {
        return parseClaims(token).getBody().getSubject();
    }

    /** type(claim) 꺼내기: access / refresh 구분용 */
    public String getType(String token) {
        Object type = parseClaims(token).getBody().get("type");
        return type != null ? type.toString() : null;
    }

    // ================== 기존 코드와의 호환용 ==================

    /**
     * 🔹 기존 generateToken(...) 쓰던 코드 깨지지 않게 유지.
     *    내부적으로 accessToken 발급으로 동작.
     */
    @Deprecated
    public String generateToken(String username) {
        return generateAccessToken(username);
    }

    /**
     * 🔹 기존 getUsername(...) → getSubject(...) 래핑
     */
    @Deprecated
    public String getUsername(String token) {
        return getSubject(token);
    }

    /**
     * 🔹 기존 validate(...) → validateToken(...) 래핑
     */
    @Deprecated
    public boolean validate(String token) {
        return validateToken(token);
    }

    // ================== 내부 공용 메서드 ==================

    private Jws<Claims> parseClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token);
    }
}
