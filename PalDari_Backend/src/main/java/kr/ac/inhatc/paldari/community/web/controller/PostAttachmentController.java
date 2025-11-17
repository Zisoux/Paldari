package kr.ac.inhatc.paldari.community.web.controller;

import kr.ac.inhatc.paldari.community.domain.post.Post;
import kr.ac.inhatc.paldari.community.domain.post.PostAttachment;
import kr.ac.inhatc.paldari.community.domain.post.PostAttachmentRepository;
import kr.ac.inhatc.paldari.community.domain.post.PostRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.File;
import java.io.IOException;
import java.security.Principal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/posts")
@CrossOrigin(origins = "*") // 필요시 (PostController와 맞추기)
public class PostAttachmentController {

    @Value("${file.upload-dir}")
    private String uploadDir;

    private final PostRepository postRepository;
    private final PostAttachmentRepository attachmentRepository;

    public PostAttachmentController(PostRepository postRepository,
                                    PostAttachmentRepository attachmentRepository) {
        this.postRepository = postRepository;
        this.attachmentRepository = attachmentRepository;
    }

    /**
     * 🔥 이미지 파일만 업로드 허용하는 API
     * - URL: POST /api/posts/{postId}/upload
     * - form-data: files (여러 개 가능)
     * - 작성자 본인만 업로드 가능
     */
    @PostMapping("/{postId}/upload")
    public ResponseEntity<List<String>> uploadFiles(
            @PathVariable Long postId,
            @RequestParam("files") List<MultipartFile> files,
            Principal principal) throws IOException {

        if (principal == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 필요");
        }

        // 1) 게시글 조회 (없으면 404)
        Post post = postRepository.findById(postId)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "게시글을 찾을 수 없습니다."));

        // 🔐 작성자 본인인지 체크
        String username = principal.getName();
        if (!username.equals(post.getAuthorUsername())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "첨부파일 업로드 권한이 없습니다.");
        }

        if (files == null || files.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "업로드할 파일이 없습니다.");
        }

        // 2) 업로드 폴더 체크 + 자동 생성
        File dir = new File(uploadDir);
        if (!dir.exists()) {
            boolean created = dir.mkdirs();
            if (!created) {
                throw new IOException("업로드 폴더 생성 실패: " + dir.getAbsolutePath());
            }
        }

        List<String> urls = new ArrayList<>();

        for (MultipartFile file : files) {
            if (file.isEmpty()) continue;

            // ============================================
            // 🔥 2-1. 이미지 파일인지 검사 (MIME + 확장자)
            // ============================================
            String contentType = file.getContentType();
            String originalName = file.getOriginalFilename() != null
                    ? file.getOriginalFilename()
                    : "";

            String lowerName = originalName.toLowerCase();

            boolean mimeOk = contentType != null && contentType.startsWith("image/");
            boolean extOk =
                    lowerName.endsWith(".png")
                            || lowerName.endsWith(".jpg")
                            || lowerName.endsWith(".jpeg")
                            || lowerName.endsWith(".gif")
                            || lowerName.endsWith(".webp");

            if (!mimeOk || !extOk) {
                // 이미지가 아니면 400 에러 반환
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "이미지 파일(png, jpg, jpeg, gif, webp)만 업로드할 수 있습니다. 잘못된 파일: " + originalName
                );
            }

            // 3) 파일 저장
            String fileName = UUID.randomUUID() + "_" + originalName;
            File dest = new File(dir, fileName);
            file.transferTo(dest);

            // 접근 가능한 URL (WebConfig에서 /uploads/** → uploadDir 매핑)
            String url = "/uploads/" + fileName;
            urls.add(url);

            // 4) DB에 첨부 정보 저장
            PostAttachment att = new PostAttachment();
            att.setPost(post);
            att.setUrl(url);
            att.setOriginalName(originalName);
            att.setCreatedAt(LocalDateTime.now());

            attachmentRepository.save(att);
        }

        return ResponseEntity.ok(urls);
    }

    /**
     * 🔥 첨부파일 단건 삭제
     * - URL: DELETE /api/posts/{postId}/attachments/{attachmentId}
     * - 작성자 본인만 삭제 가능
     * - DB 레코드 + 실제 파일 둘 다 삭제 시도
     */
    @DeleteMapping("/{postId}/attachments/{attachmentId}")
    public ResponseEntity<Void> deleteAttachment(
            @PathVariable Long postId,
            @PathVariable Long attachmentId,
            Principal principal) {

        if (principal == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 필요");
        }

        String username = principal.getName();

        // 1) 게시글 조회
        Post post = postRepository.findById(postId)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "게시글을 찾을 수 없습니다."));

        // 🔐 본인 글인지 체크
        if (!username.equals(post.getAuthorUsername())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "첨부파일 삭제 권한이 없습니다.");
        }

        // 2) 첨부파일 조회
        PostAttachment attachment = attachmentRepository.findById(attachmentId)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND, "첨부파일을 찾을 수 없습니다."));

        // 2-1) 해당 게시글의 첨부파일이 맞는지 확인
        if (!attachment.getPost().getId().equals(postId)) {
            // 다른 게시글에 속한 첨부면 400 또는 404
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "요청한 게시글에 속한 첨부파일이 아닙니다.");
        }

        // 3) 실제 파일 삭제 시도 (실패해도 예외는 안 던지고 로그 수준으로만 다룰 수 있음)
        String url = attachment.getUrl();
        if (url != null && !url.isBlank()) {
            String fileName = url;
            if (fileName.startsWith("/uploads/")) {
                fileName = fileName.substring("/uploads/".length());
            }
            File file = new File(uploadDir, fileName);
            if (file.exists()) {
                // 삭제 실패해도 서비스 동작까지 막을 필요는 없어서 결과는 체크만
                boolean deleted = file.delete();
                if (!deleted) {
                    // 필요하면 로그 라이브러리로 경고 출력
                    System.err.println("파일 삭제 실패: " + file.getAbsolutePath());
                }
            }
        }

        // 4) DB 레코드 삭제
        attachmentRepository.delete(attachment);

        return ResponseEntity.noContent().build();
    }
}
