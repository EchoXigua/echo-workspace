package com.leanmate.user.domain;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import org.springframework.stereotype.Component;

@Component
public class ProfileCalculator {

    private static final BigDecimal MIN_TARGET_BMI = new BigDecimal("18.5");
    private static final double KCAL_PER_KG = 7700.0;
    private static final double DEFAULT_DEFICIT_RATE = 0.15;
    private static final double MIN_DAILY_DEFICIT_KCAL = 300.0;
    private static final double MAX_DAILY_DEFICIT_KCAL = 750.0;

    public ProfileCalculationResult calculate(
            Gender gender,
            int age,
            BigDecimal heightCm,
            BigDecimal currentWeightKg,
            BigDecimal targetWeightKg,
            ActivityLevel activityLevel,
            LocalDate targetDate,
            LocalDate today
    ) {
        validateTargetWeight(heightCm, targetWeightKg);

        BigDecimal bmi = calculateBmi(heightCm, currentWeightKg);
        int bmrKcal = calculateBmr(gender, age, heightCm, currentWeightKg);
        int dailyCalorieTargetKcal = calculateDailyCalorieTarget(
                gender,
                bmrKcal,
                currentWeightKg,
                targetWeightKg,
                activityLevel,
                targetDate,
                today);

        return new ProfileCalculationResult(bmi, bmrKcal, dailyCalorieTargetKcal);
    }

    private BigDecimal calculateBmi(BigDecimal heightCm, BigDecimal currentWeightKg) {
        BigDecimal heightM = heightCm.divide(new BigDecimal("100"), 6, RoundingMode.HALF_UP);
        BigDecimal heightSquare = heightM.multiply(heightM);
        return currentWeightKg.divide(heightSquare, 2, RoundingMode.HALF_UP);
    }

    private int calculateBmr(Gender gender, int age, BigDecimal heightCm, BigDecimal currentWeightKg) {
        double bmr = 10 * currentWeightKg.doubleValue()
                + 6.25 * heightCm.doubleValue()
                - 5 * age
                + gender.bmrConstant();
        return (int) Math.round(bmr);
    }

    private int calculateDailyCalorieTarget(
            Gender gender,
            int bmrKcal,
            BigDecimal currentWeightKg,
            BigDecimal targetWeightKg,
            ActivityLevel activityLevel,
            LocalDate targetDate,
            LocalDate today
    ) {
        double tdee = bmrKcal * activityLevel.multiplier();
        double deficit = calculateDeficit(tdee, currentWeightKg, targetWeightKg, targetDate, today);
        long roundedTarget = Math.round((tdee - deficit) / 10.0) * 10;
        return (int) Math.max(roundedTarget, gender.calorieFloorKcal());
    }

    private double calculateDeficit(
            double tdee,
            BigDecimal currentWeightKg,
            BigDecimal targetWeightKg,
            LocalDate targetDate,
            LocalDate today
    ) {
        double weightLossKg = currentWeightKg.subtract(targetWeightKg).doubleValue();
        if (weightLossKg <= 0) {
            return 0;
        }

        double deficit = tdee * DEFAULT_DEFICIT_RATE;
        if (targetDate != null) {
            long days = ChronoUnit.DAYS.between(today, targetDate);
            if (days > 0) {
                deficit = weightLossKg * KCAL_PER_KG / days;
            }
        }
        return Math.min(Math.max(deficit, MIN_DAILY_DEFICIT_KCAL), MAX_DAILY_DEFICIT_KCAL);
    }

    private void validateTargetWeight(BigDecimal heightCm, BigDecimal targetWeightKg) {
        BigDecimal heightM = heightCm.divide(new BigDecimal("100"), 6, RoundingMode.HALF_UP);
        BigDecimal targetBmi = targetWeightKg.divide(heightM.multiply(heightM), 2, RoundingMode.HALF_UP);
        if (targetBmi.compareTo(MIN_TARGET_BMI) < 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "目标体重低于安全阈值");
        }
    }
}
