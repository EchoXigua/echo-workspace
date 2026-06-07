package com.leanmate.ai.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record DailyReportSnapshotInput(
        LocalDate date,
        int calorieTargetKcal,
        int caloriesKcal,
        int remainingCaloriesKcal,
        BigDecimal proteinG,
        BigDecimal fatG,
        BigDecimal carbsG,
        int foodEntryCount,
        BigDecimal weightKg
) {
}
