package kr.ac.inhatc.paldari.auth.repository;

import kr.ac.inhatc.paldari.auth.entity.User;
import kr.ac.inhatc.paldari.auth.entity.UserRegion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserRegionRepository extends JpaRepository<UserRegion, Long> {
    List<UserRegion> findByUser(User user);
    void deleteByUserAndRegion(User user, String region);
    boolean existsByUserAndRegion(User user, String region);
}
