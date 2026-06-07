package com.leanmate.ai.dto;

import java.math.BigDecimal;

public record DailyReportProfileInput(
        String gender,
        int age,
        BigDecimal heightCm,
        BigDecimal currentWeightKg,
        BigDecimal targetWeightKg,
        String activityLevel,
        int dailyCalorieTargetKcal
) {
}
