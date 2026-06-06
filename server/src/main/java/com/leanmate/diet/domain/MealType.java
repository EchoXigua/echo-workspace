package com.leanmate.diet.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;

public enum MealType {
    BREAKFAST("breakfast"),
    LUNCH("lunch"),
    DINNER("dinner"),
    SNACK("snack");

    private final String value;

    MealType(String value) {
        this.value = value;
    }

    @JsonValue
    public String value() {
        return value;
    }

    @JsonCreator
    public static MealType fromValue(String value) {
        return Arrays.stream(values())
                .filter(type -> type.value.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("不支持的餐次"));
    }
}
