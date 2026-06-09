package com.leanmate.diet.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;

public enum NutritionSource {
    FOOD_DB("food_db"),
    AI_ESTIMATED("ai_estimated"),
    USER_CONFIRMED("user_confirmed"),
    USER_OVERRIDE("user_override");

    private final String value;

    NutritionSource(String value) {
        this.value = value;
    }

    @JsonValue
    public String value() {
        return value;
    }

    @JsonCreator
    public static NutritionSource fromValue(String value) {
        return Arrays.stream(values())
                .filter(source -> source.value.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("不支持的营养来源"));
    }
}
