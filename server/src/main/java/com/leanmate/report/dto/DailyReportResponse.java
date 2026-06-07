package com.leanmate.report.dto;

import com.leanmate.report.domain.DailyReportStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record DailyReportResponse(
        UUID id,
        LocalDate reportDate,
        Integer score,
        String summary,
        String problem,
        String suggestion,
        DailyReportStatus status,
        Instant generatedAt,
        Instant viewedAt
) {
}
