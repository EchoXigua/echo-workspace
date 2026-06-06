package com.leanmate.user.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;

public enum Gender {
    MALE("male", 5, 1500),
    FEMALE("female", -161, 1200),
    UNKNOWN("unknown", -78, 1300);

    private final String value;
    private final int bmrConstant;
    private final int calorieFloorKcal;

    Gender(String value, int bmrConstant, int calorieFloorKcal) {
        this.value = value;
        this.bmrConstant = bmrConstant;
        this.calorieFloorKcal = calorieFloorKcal;
    }

    @JsonValue
    public String value() {
        return value;
    }

    public int bmrConstant() {
        return bmrConstant;
    }

    public int calorieFloorKcal() {
        return calorieFloorKcal;
    }

    @JsonCreator
    public static Gender fromValue(String value) {
        return Arrays.stream(values())
                .filter(gender -> gender.value.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("不支持的性别"));
    }
}
