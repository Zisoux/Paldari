package kr.ac.inhatc.paldari.auth.config;

import jakarta.servlet.http.HttpServletResponse;
import kr.ac.inhatc.paldari.auth.jwt.JwtAuthenticationFilter;
import kr.ac.inhatc.paldari.auth.jwt.JwtTokenProvider;
import kr.ac.inhatc.paldari.auth.service.CustomOidcUserService;
import kr.ac.inhatc.paldari.auth.service.OAuth2LoginSuccessHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
public class SecurityConfig {

    private final JwtTokenProvider jwtTokenProvider;
    /**
     * ⚠️ 중요:
     * 이 CustomOAuth2UserService는 OIDC 대응 버전이어야 한다.
     * (OidcUserService를 상속하거나, OidcUserRequest를 처리하도록 구현)
     * 앞에서 만들어둔 "email 기준으로 DB 저장하는" 버전.
     */
    private final CustomOidcUserService customOidcUserService;
    private final OAuth2LoginSuccessHandler oAuth2LoginSuccessHandler;

    public SecurityConfig(
            JwtTokenProvider jwtTokenProvider,
            CustomOidcUserService customOidcUserService,
            OAuth2LoginSuccessHandler oAuth2LoginSuccessHandler
    ) {
        this.jwtTokenProvider = jwtTokenProvider;
        this.customOidcUserService = customOidcUserService;
        this.oAuth2LoginSuccessHandler = oAuth2LoginSuccessHandler;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            UserDetailsService userDetailsService
    ) throws Exception {

        // JWT 필터: 토큰 → UserDetailsService → SecurityContext 세팅
        JwtAuthenticationFilter jwtFilter =
                new JwtAuthenticationFilter(jwtTokenProvider, userDetailsService);

        http
                // 세션 X, CSRF X, CORS 기본
                .csrf(AbstractHttpConfigurer::disable)
                .cors(Customizer.withDefaults())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // 인증 실패 공통 처리
                .exceptionHandling(ex -> ex.authenticationEntryPoint(
                        (req, res, e) -> res.sendError(HttpServletResponse.SC_UNAUTHORIZED)))

                // 인가 설정
                .authorizeHttpRequests(reg -> reg
                        // 인증 없이 허용
                        .requestMatchers(
                                "/",
                                "/api/auth/**",
                                "/oauth2/**",
                                "/login/oauth2/**",
                                "/oauth-success"
                        ).permitAll()
                        // 정적 리소스 & 웹소켓 엔드포인트
                        .requestMatchers("/uploads/**").permitAll()
                        .requestMatchers("/ws-chat/**").permitAll()
                        // 게시글 조회는 공개
                        .requestMatchers(HttpMethod.GET, "/api/posts/**").permitAll()
                        // 글쓰기/수정/삭제는 인증 필요
                        .requestMatchers("/api/posts/**").authenticated()
                        // ⭐ 평점 API는 인증 필요
                        .requestMatchers("/api/ratings/**").authenticated()
                        // 채팅 API는 인증 필요
                        .requestMatchers("/api/chat/**").authenticated()
                        // 프로필 관련은 인증 필요 (rating-summary 포함)
                        .requestMatchers("/api/profile/**").authenticated()
                        // 나머지는 전부 인증 필요
                        .anyRequest().authenticated()
                )

                // OAuth2 / OIDC 로그인 설정
                .oauth2Login(oauth -> oauth
                        .userInfoEndpoint(u -> u
                                // 🔥 OIDC 모드에서는 oidcUserService 사용해야 커스텀 서비스가 탄다
                                .oidcUserService(customOidcUserService)
                        )
                        // 로그인 성공 시: DB에 있는 유저 기준으로 JWT 생성 + 프론트로 리다이렉트
                        .successHandler(oAuth2LoginSuccessHandler)
                        // 실패 시 401
                        .failureHandler((req, res, ex) ->
                                res.sendError(HttpServletResponse.SC_UNAUTHORIZED, "OAuth2 login failed"))
                )

                // (옵션) 기본 httpBasic 허용
                .httpBasic(Customizer.withDefaults());

        // JWT 필터를 UsernamePasswordAuthenticationFilter 앞에 등록
        http.addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration cfg = new CorsConfiguration();
        cfg.setAllowedOrigins(List.of(
                "http://localhost:3000",
                "http://127.0.0.1:3000",
                "http://localhost:5173",
                "http://localhost:52736",
                "http://localhost:49816"
        ));
        cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        cfg.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With"));
        cfg.setExposedHeaders(List.of("Authorization"));
        cfg.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", cfg);
        return source;
    }

    @Bean
    public BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
