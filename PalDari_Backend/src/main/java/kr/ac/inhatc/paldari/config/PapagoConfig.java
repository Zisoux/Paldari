package kr.ac.inhatc.paldari.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class PapagoConfig {

    @Bean
    public WebClient papagoWebClient(
            @Value("${papago.base-url}") String baseUrl,
            @Value("${papago.api-key-id}") String apiKeyId,
            @Value("${papago.api-key}") String apiKey
    ) {
        return WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("X-NCP-APIGW-API-KEY-ID", apiKeyId)
                .defaultHeader("X-NCP-APIGW-API-KEY", apiKey)
                .build();
    }
}
