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
    private static final double DEFAULT_SURPLUS_RATE = 0.10;
    private static final double MIN_DAILY_DEFICIT_KCAL = 300.0;
    private static final double MAX_DAILY_DEFICIT_KCAL = 750.0;
    private static final double MIN_DAILY_SURPLUS_KCAL = 150.0;
    private static final double MAX_DAILY_SURPLUS_KCAL = 500.0;

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
        return calculate(
                gender,
                age,
                heightCm,
                currentWeightKg,
                targetWeightKg,
                GoalType.infer(currentWeightKg, targetWeightKg),
                activityLevel,
                targetDate,
                today);
    }

    public ProfileCalculationResult calculate(
            Gender gender,
            int age,
            BigDecimal heightCm,
            BigDecimal currentWeightKg,
            BigDecimal targetWeightKg,
            GoalType goalType,
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
                goalType,
                activityLevel,
                targetDate,
                today);
        BigDecimal weeklyTargetWeightChangeKg = calculateWeeklyTargetWeightChangeKg(
                currentWeightKg,
                targetWeightKg,
                goalType,
                targetDate,
                today);

        return new ProfileCalculationResult(bmi, bmrKcal, dailyCalorieTargetKcal, weeklyTargetWeightChangeKg);
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
            GoalType goalType,
            ActivityLevel activityLevel,
            LocalDate targetDate,
            LocalDate today
    ) {
        double tdee = bmrKcal * activityLevel.multiplier();
        double adjustment = switch (goalType) {
            case LOSE_WEIGHT -> -calculateDeficit(tdee, currentWeightKg, targetWeightKg, targetDate, today);
            case GAIN_WEIGHT -> calculateSurplus(tdee, currentWeightKg, targetWeightKg, targetDate, today);
            case MAINTAIN -> 0;
        };
        long roundedTarget = Math.round((tdee + adjustment) / 10.0) * 10;
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

    private double calculateSurplus(
            double tdee,
            BigDecimal currentWeightKg,
            BigDecimal targetWeightKg,
            LocalDate targetDate,
            LocalDate today
    ) {
        double weightGainKg = targetWeightKg.subtract(currentWeightKg).doubleValue();
        if (weightGainKg <= 0) {
            return 0;
        }

        double surplus = tdee * DEFAULT_SURPLUS_RATE;
        if (targetDate != null) {
            long days = ChronoUnit.DAYS.between(today, targetDate);
            if (days > 0) {
                surplus = weightGainKg * KCAL_PER_KG / days;
            }
        }
        return Math.min(Math.max(surplus, MIN_DAILY_SURPLUS_KCAL), MAX_DAILY_SURPLUS_KCAL);
    }

    private BigDecimal calculateWeeklyTargetWeightChangeKg(
            BigDecimal currentWeightKg,
            BigDecimal targetWeightKg,
            GoalType goalType,
            LocalDate targetDate,
            LocalDate today
    ) {
        if (goalType == GoalType.MAINTAIN) {
            return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        }
        BigDecimal totalChangeKg = targetWeightKg.subtract(currentWeightKg);
        if (targetDate != null) {
            long days = ChronoUnit.DAYS.between(today, targetDate);
            if (days > 0) {
                return totalChangeKg
                        .multiply(new BigDecimal("7"))
                        .divide(new BigDecimal(days), 2, RoundingMode.HALF_UP);
            }
        }
        return goalType == GoalType.GAIN_WEIGHT
                ? new BigDecimal("0.25")
                : new BigDecimal("-0.40");
    }

    private void validateTargetWeight(BigDecimal heightCm, BigDecimal targetWeightKg) {
        BigDecimal heightM = heightCm.divide(new BigDecimal("100"), 6, RoundingMode.HALF_UP);
        BigDecimal targetBmi = targetWeightKg.divide(heightM.multiply(heightM), 2, RoundingMode.HALF_UP);
        if (targetBmi.compareTo(MIN_TARGET_BMI) < 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "目标体重低于安全阈值");
        }
    }
}
