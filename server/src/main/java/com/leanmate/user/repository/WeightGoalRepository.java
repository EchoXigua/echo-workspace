package com.leanmate.user.repository;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WeightGoalRepository extends JpaRepository<WeightGoalEntity, UUID> {

    Optional<WeightGoalEntity> findFirstByUserIdAndStatusOrderByCreatedAtDesc(UUID userId, String status);
}
