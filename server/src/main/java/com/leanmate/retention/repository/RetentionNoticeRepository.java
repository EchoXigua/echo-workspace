package com.leanmate.retention.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RetentionNoticeRepository extends JpaRepository<RetentionNoticeEntity, UUID> {

    List<RetentionNoticeEntity> findByUserIdAndStatusOrderByTriggeredAtAsc(UUID userId, String status);

    Optional<RetentionNoticeEntity> findByUserIdAndTypeAndMilestoneValue(UUID userId, String type, Integer milestoneValue);
}
