package com.leanmate.user.dto;

import com.leanmate.user.domain.GoalType;
import java.math.BigDecimal;
import java.time.LocalDate;

public record PlanOverviewGoalResponse(
        GoalType goalType,
        BigDecimal startWeightKg,
        BigDecimal targetWeightKg,
        BigDecimal remainingWeightKg,
        LocalDate targetDate,
        int dailyCalorieTargetKcal,
        int estimatedActivityEnergyKcal,
        BigDecimal weeklyTargetWeightChangeKg,
        String status
) {
}
