package com.leanmate.user.dto;

import com.leanmate.user.domain.ActivityLevel;
import com.leanmate.user.domain.Gender;
import com.leanmate.user.domain.GoalType;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;

public record SaveUserProfileRequest(
        @NotNull Gender gender,
        @NotNull @Min(1) @Max(120) Integer age,
        @NotNull @DecimalMin("50.0") @DecimalMax("250.0") BigDecimal heightCm,
        @NotNull @DecimalMin("20.0") @DecimalMax("300.0") BigDecimal currentWeightKg,
        @NotNull @DecimalMin("20.0") @DecimalMax("300.0") BigDecimal targetWeightKg,
        GoalType goalType,
        @NotNull ActivityLevel activityLevel,
        @NotBlank @Size(max = 64) String timezone,
        LocalDate targetDate
) {
    public SaveUserProfileRequest(
            Gender gender,
            Integer age,
            BigDecimal heightCm,
            BigDecimal currentWeightKg,
            BigDecimal targetWeightKg,
            ActivityLevel activityLevel,
            String timezone,
            LocalDate targetDate
    ) {
        this(
                gender,
                age,
                heightCm,
                currentWeightKg,
                targetWeightKg,
                null,
                activityLevel,
                timezone,
                targetDate);
    }
}
