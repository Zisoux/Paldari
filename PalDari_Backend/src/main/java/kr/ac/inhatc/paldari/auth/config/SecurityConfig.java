package kr.ac.inhatc.paldari.auth.config;

import jakarta.servlet.http.HttpServletResponse;
import kr.ac.inhatc.paldari.auth.jwt.JwtAuthenticationFilter;
import kr.ac.inhatc.paldari.auth.jwt.JwtTokenProvider;
import kr.ac.inhatc.paldari.auth.service.OAuth2UserService;
import kr.ac.inhatc.paldari.auth.service.UserService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
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
    private final OAuth2UserService oAuth2UserService; // 커스텀: OAuth2UserService + SuccessHandler

    public SecurityConfig(JwtTokenProvider jwtTokenProvider,
                          OAuth2UserService oAuth2UserService) {
        this.jwtTokenProvider = jwtTokenProvider;
        this.oAuth2UserService = oAuth2UserService;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http,
                                                   UserDetailsService uds) throws Exception {
        JwtAuthenticationFilter jwtFilter = new JwtAuthenticationFilter(jwtTokenProvider, uds);

        http
                .securityMatcher("/api/**", "/oauth2/**", "/login/oauth2/**")
                .cors(Customizer.withDefaults())
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(ex -> ex.authenticationEntryPoint((req, res, e) -> res.sendError(HttpServletResponse.SC_UNAUTHORIZED)))
                .authorizeHttpRequests(reg -> reg
                        .requestMatchers(HttpMethod.OPTIONS, "/api/**", "/oauth2/**", "/login/oauth2/**").permitAll()
                        .requestMatchers("/api/auth/signup", "/api/auth/login", "/api/auth/verify").permitAll()
                        .requestMatchers("/oauth2/**", "/login/oauth2/**").permitAll()
                        .anyRequest().authenticated()
                )
                .oauth2Login(oauth -> oauth
                        .userInfoEndpoint(u -> u.userService(oAuth2UserService))
                        .successHandler(oAuth2UserService)
                        .failureHandler((req, res, ex) -> res.sendError(HttpServletResponse.SC_UNAUTHORIZED, "OAuth2 login failed"))
                )
                .httpBasic(Customizer.withDefaults());

        http.addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }


    // 2) CORS 정책 Bean
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration cfg = new CorsConfiguration();
        // 개발용: 프론트 오리진(정확히) 명시. credentials(true)면 "*" 못 씀
        cfg.setAllowedOrigins(List.of(
                "http://localhost:3000",
                "http://127.0.0.1:3000",
                "http://localhost:5173"   // 예: Vite
                // 필요시 추가
        ));
        cfg.setAllowedMethods(List.of("GET","POST","PUT","PATCH","DELETE","OPTIONS"));
        cfg.setAllowedHeaders(List.of("Authorization","Content-Type","X-Requested-With"));
        // 클라이언트가 응답에서 읽을 수 있게 노출할 헤더
        cfg.setExposedHeaders(List.of("Authorization"));
        // 쿠키/인증정보를 보낼 경우
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
