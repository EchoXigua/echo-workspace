package com.leanmate.ai.repository;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AiModelCallLogRepository extends JpaRepository<AiModelCallLogEntity, UUID> {
}
