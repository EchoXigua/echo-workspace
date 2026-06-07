package com.leanmate.ai.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record DailyReportGoalInput(
        BigDecimal startWeightKg,
        BigDecimal targetWeightKg,
        LocalDate targetDate,
        int dailyCalorieTargetKcal
) {
}
