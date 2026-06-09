package com.leanmate.weight.domain;

import com.fasterxml.jackson.annotation.JsonValue;

public enum WeightTrendDirection {
    DECREASING("decreasing"),
    INCREASING("increasing"),
    FLAT("flat");

    private final String value;

    WeightTrendDirection(String value) {
        this.value = value;
    }

    @JsonValue
    public String value() {
        return value;
    }
}
