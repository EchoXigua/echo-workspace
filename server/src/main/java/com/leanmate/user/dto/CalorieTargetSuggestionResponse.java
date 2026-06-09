package com.leanmate.user.dto;

import java.math.BigDecimal;

public record CalorieTargetSuggestionResponse(
        String status,
        int currentTargetKcal,
        int suggestedTargetKcal,
        int changeKcal,
        String reason,
        boolean requiresUserConfirmation,
        int trendDays,
        BigDecimal startAverageWeightKg,
        BigDecimal endAverageWeightKg,
        BigDecimal weeklyWeightChangeKg
) {
}
