package com.leanmate.user.repository;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserProfileRepository extends JpaRepository<UserProfileEntity, UUID> {

    boolean existsByUserId(UUID userId);

    Optional<UserProfileEntity> findByUserId(UUID userId);
}
