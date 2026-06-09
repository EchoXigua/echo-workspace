package com.leanmate.user.dto;

import com.leanmate.user.domain.ActivityLevel;
import com.leanmate.user.domain.Gender;
import java.math.BigDecimal;

public record PlanOverviewProfileResponse(
        Gender gender,
        int age,
        BigDecimal heightCm,
        BigDecimal currentWeightKg,
        BigDecimal targetWeightKg,
        ActivityLevel activityLevel,
        String activityLevelLabel,
        BigDecimal bmi,
        int bmrKcal
) {
}
