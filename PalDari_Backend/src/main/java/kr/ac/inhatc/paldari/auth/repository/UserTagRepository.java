package kr.ac.inhatc.paldari.auth.repository;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.entity.UserTag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserTagRepository extends JpaRepository<UserTag, Long> {
    List<UserTag> findByUser(User user);
    void deleteByUserAndTag(User user, String tag);
    boolean existsByUserAndTag(User user, String tag);
}

