package com.leanmate.user.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
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
    void rejectUnsafeTargetWeight() {
        assertThatThrownBy(() -> profileCalculator.calculate(
                Gender.FEMALE,
                30,
                new BigDecimal("160"),
                new BigDecimal("60"),
                new BigDecimal("40"),
                ActivityLevel.SEDENTARY,
                null,
                LocalDate.parse("2026-06-06")))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.BAD_REQUEST);
    }
}
