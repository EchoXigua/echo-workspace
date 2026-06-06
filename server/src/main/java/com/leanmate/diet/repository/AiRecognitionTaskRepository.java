package com.leanmate.diet.repository;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AiRecognitionTaskRepository extends JpaRepository<AiRecognitionTaskEntity, UUID> {
}
