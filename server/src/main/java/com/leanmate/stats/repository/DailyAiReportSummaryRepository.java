package com.leanmate.stats.repository;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

public interface DailyAiReportSummaryRepository extends Repository<DailyNutritionSnapshotEntity, UUID> {

    @Query(value = """
            select summary
            from daily_ai_reports
            where user_id = :userId
              and report_date = :date
              and status in ('generated', 'viewed')
            order by created_at desc
            limit 1
            """, nativeQuery = true)
    Optional<String> findGeneratedSummary(
            @Param("userId") UUID userId,
            @Param("date") LocalDate date);
}
