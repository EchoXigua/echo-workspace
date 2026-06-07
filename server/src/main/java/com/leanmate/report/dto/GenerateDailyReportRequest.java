package com.leanmate.report.dto;

import java.time.LocalDate;

public record GenerateDailyReportRequest(
        LocalDate date
) {
}
