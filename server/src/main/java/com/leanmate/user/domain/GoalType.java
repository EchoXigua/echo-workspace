package com.leanmate.user.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.math.BigDecimal;
import java.util.Arrays;

public enum GoalType {
    LOSE_WEIGHT("lose_weight"),
    GAIN_WEIGHT("gain_weight"),
    MAINTAIN("maintain");

    private final String value;

    GoalType(String value) {
        this.value = value;
    }

    @JsonValue
    public String value() {
        return value;
    }

    @JsonCreator
    public static GoalType fromValue(String value) {
        return Arrays.stream(values())
                .filter(type -> type.value.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("不支持的目标类型"));
    }

    public static GoalType infer(BigDecimal currentWeightKg, BigDecimal targetWeightKg) {
        int comparison = targetWeightKg.compareTo(currentWeightKg);
        if (comparison < 0) {
            return LOSE_WEIGHT;
        }
        if (comparison > 0) {
            return GAIN_WEIGHT;
        }
        return MAINTAIN;
    }
}
