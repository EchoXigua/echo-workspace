package com.leanmate.user.dto;

import com.leanmate.user.domain.ActivityLevel;
import com.leanmate.user.domain.Gender;
import java.math.BigDecimal;
import java.time.LocalDate;

public record UserProfileResponse(
        Gender gender,
        int age,
        BigDecimal heightCm,
        BigDecimal currentWeightKg,
        BigDecimal targetWeightKg,
        ActivityLevel activityLevel,
        String timezone,
        LocalDate targetDate,
        BigDecimal bmi,
        int bmrKcal,
        int dailyCalorieTargetKcal
) {
}
