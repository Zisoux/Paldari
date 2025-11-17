package kr.ac.inhatc.paldari.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Paths;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 프로젝트 루트의 ./uploads 를 절대 경로로 변환
        String uploadPath = Paths.get("uploads").toAbsolutePath().toUri().toString();
        // 예: file:/Users/고현아/workspace/paldari/uploads/

        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:/Users/test/Documents/GitHub/Paldari/PalDari_Backend/uploads/");

    }
}
