package com.leanmate.report.repository;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DailyAiReportRepository extends JpaRepository<DailyAiReportEntity, UUID> {

    Optional<DailyAiReportEntity> findByUserIdAndReportDate(UUID userId, LocalDate reportDate);
}
