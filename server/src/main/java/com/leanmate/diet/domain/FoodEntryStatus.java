package com.leanmate.diet.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;

public enum FoodEntryStatus {
    DRAFT("draft"),
    CONFIRMED("confirmed"),
    DELETED("deleted");

    private final String value;

    FoodEntryStatus(String value) {
        this.value = value;
    }

    @JsonValue
    public String value() {
        return value;
    }

    @JsonCreator
    public static FoodEntryStatus fromValue(String value) {
        return Arrays.stream(values())
                .filter(status -> status.value.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("不支持的饮食记录状态"));
    }
}
