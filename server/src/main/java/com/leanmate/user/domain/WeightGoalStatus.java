package com.leanmate.user.domain;

public enum WeightGoalStatus {
    ACTIVE("active"),
    COMPLETED("completed"),
    CANCELLED("cancelled");

    private final String value;

    WeightGoalStatus(String value) {
        this.value = value;
    }

    public String value() {
        return value;
    }
}
