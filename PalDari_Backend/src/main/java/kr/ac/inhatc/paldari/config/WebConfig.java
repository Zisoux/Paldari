package kr.ac.inhatc.paldari.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    /**
     * application.yml / application-local.yml 에서 불러오는 업로드 경로
     * ex)
     *  mac  → /Users/너이름/paldari_uploads
     *  win  → D:/paldari_uploads
     *  linux → /home/ubuntu/uploads
     */
    @Value("${app.upload-dir}")
    private String uploadDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {

        // 윈도우/맥/리눅스 모두 동작하도록 마지막에 슬래시 붙이기
        String path = "file:" + (uploadDir.endsWith("/") ? uploadDir : uploadDir + "/");

        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(path);
    }
}
