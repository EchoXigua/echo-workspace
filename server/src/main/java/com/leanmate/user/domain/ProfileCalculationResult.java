package com.leanmate.user.domain;

import java.math.BigDecimal;

public record ProfileCalculationResult(
        BigDecimal bmi,
        int bmrKcal,
        int dailyCalorieTargetKcal,
        BigDecimal weeklyTargetWeightChangeKg
) {
}
