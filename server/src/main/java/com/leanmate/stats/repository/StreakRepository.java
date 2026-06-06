package com.leanmate.stats.repository;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StreakRepository extends JpaRepository<StreakEntity, UUID> {

    Optional<StreakEntity> findByUserId(UUID userId);
}
