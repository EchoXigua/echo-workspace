package com.leanmate.user.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;

public enum ActivityLevel {
    SEDENTARY("sedentary", 1.2),
    LIGHT("light", 1.375),
    MODERATE("moderate", 1.55),
    ACTIVE("active", 1.725),
    VERY_ACTIVE("very_active", 1.9);

    private final String value;
    private final double multiplier;

    ActivityLevel(String value, double multiplier) {
        this.value = value;
        this.multiplier = multiplier;
    }

    @JsonValue
    public String value() {
        return value;
    }

    public double multiplier() {
        return multiplier;
    }

    @JsonCreator
    public static ActivityLevel fromValue(String value) {
        return Arrays.stream(values())
                .filter(level -> level.value.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("不支持的活动水平"));
    }
}
