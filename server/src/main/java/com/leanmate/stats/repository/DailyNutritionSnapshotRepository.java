package com.leanmate.stats.repository;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DailyNutritionSnapshotRepository extends JpaRepository<DailyNutritionSnapshotEntity, UUID> {

    Optional<DailyNutritionSnapshotEntity> findByUserIdAndDate(UUID userId, LocalDate date);
}
