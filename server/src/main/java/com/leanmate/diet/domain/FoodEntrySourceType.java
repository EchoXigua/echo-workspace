package com.leanmate.diet.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;

public enum FoodEntrySourceType {
    PHOTO("photo"),
    TEXT("text"),
    MANUAL("manual");

    private final String value;

    FoodEntrySourceType(String value) {
        this.value = value;
    }

    @JsonValue
    public String value() {
        return value;
    }

    @JsonCreator
    public static FoodEntrySourceType fromValue(String value) {
        return Arrays.stream(values())
                .filter(type -> type.value.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("不支持的记录来源"));
    }
}
