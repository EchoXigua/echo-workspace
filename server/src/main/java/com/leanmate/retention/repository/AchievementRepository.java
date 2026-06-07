package com.leanmate.retention.repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AchievementRepository extends JpaRepository<AchievementEntity, UUID> {

    List<AchievementEntity> findByUserIdAndTypeIn(UUID userId, Collection<String> types);
}
