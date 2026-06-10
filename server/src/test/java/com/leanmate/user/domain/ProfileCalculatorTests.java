package com.leanmate.user.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class ProfileCalculatorTests {

    private final ProfileCalculator profileCalculator = new ProfileCalculator();

    @Test
    void calculateDefaultProfileMetrics() {
        ProfileCalculationResult result = profileCalculator.calculate(
                Gender.MALE,
                30,
                new BigDecimal("170"),
                new BigDecimal("80"),
                new BigDecimal("70"),
                ActivityLevel.MODERATE,
                null,
                LocalDate.parse("2026-06-06"));

        assertThat(result.bmi()).isEqualByComparingTo("27.68");
        assertThat(result.bmrKcal()).isEqualTo(1718);
        assertThat(result.dailyCalorieTargetKcal()).isEqualTo(2260);
    }

    @Test
    void clampAggressiveTargetDateDeficit() {
        ProfileCalculationResult result = profileCalculator.calculate(
                Gender.MALE,
                30,
                new BigDecimal("170"),
                new BigDecimal("80"),
                new BigDecimal("70"),
                ActivityLevel.MODERATE,
                LocalDate.parse("2026-09-14"),
                LocalDate.parse("2026-06-06"));

        assertThat(result.dailyCalorieTargetKcal()).isEqualTo(1910);
    }

    @Test
    void calculateGainWeightTargetWithSurplus() {
        ProfileCalculationResult result = profileCalculator.calculate(
                Gender.MALE,
                30,
                new BigDecimal("170"),
                new BigDecimal("70"),
                new BigDecimal("80"),
                GoalType.GAIN_WEIGHT,
                ActivityLevel.MODERATE,
                null,
                LocalDate.parse("2026-06-06"));

        assertThat(result.bmi()).isEqualByComparingTo("24.22");
        assertThat(result.bmrKcal()).isEqualTo(1618);
        assertThat(result.dailyCalorieTargetKcal()).isEqualTo(2760);
        assertThat(result.weeklyTargetWeightChangeKg()).isEqualByComparingTo("0.25");
    }

    @Test
    void calculateLowTargetWeightWithinDtoRange() {
        ProfileCalculationResult result = profileCalculator.calculate(
                Gender.FEMALE,
                30,
                new BigDecimal("160"),
                new BigDecimal("60"),
                new BigDecimal("40"),
                ActivityLevel.SEDENTARY,
                null,
        LocalDate.parse("2026-06-06"));

        assertThat(result.bmi()).isEqualByComparingTo("23.44");
        assertThat(result.dailyCalorieTargetKcal()).isEqualTo(1250);
    }
}
