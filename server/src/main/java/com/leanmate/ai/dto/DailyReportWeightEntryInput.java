package com.leanmate.ai.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record DailyReportWeightEntryInput(
        LocalDate recordDate,
        BigDecimal weightKg
) {
}
