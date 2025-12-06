package kr.ac.inhatc.paldari.auth.repository;

import kr.ac.inhatc.paldari.auth.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
    Optional<User> findByEmail(String email);

    Optional<User> findByUsernameAndEmail(String username, String email);

    void deleteByUsername(String username);

    @Query("""
        select distinct u
        from User u
        left join fetch u.settings s
        left join fetch u.regions r
        left join fetch u.tags t
        where u.id <> :userId
          and (s is null or s.allowMatching = true)
        """)
    List<User> findAllPalsForUser(@Param("userId") Long userId);
}
