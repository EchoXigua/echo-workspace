package com.leanmate.stats.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record TodayHomeResponse(
        LocalDate date,
        boolean profileCompleted,
        int calorieTargetKcal,
        int caloriesInKcal,
        int remainingCaloriesKcal,
        BigDecimal proteinG,
        BigDecimal fatG,
        BigDecimal carbsG,
        BigDecimal currentWeightKg,
        int streakDays,
        String reportSummary,
        List<FoodEntrySummaryResponse> foodEntries
) {
}
