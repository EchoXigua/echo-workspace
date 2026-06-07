package com.leanmate.report.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;

public enum DailyReportStatus {
    PENDING("pending"),
    GENERATED("generated"),
    VIEWED("viewed"),
    FAILED("failed");

    private final String value;

    DailyReportStatus(String value) {
        this.value = value;
    }

    @JsonValue
    public String value() {
        return value;
    }

    @JsonCreator
    public static DailyReportStatus fromValue(String value) {
        return Arrays.stream(values())
                .filter(status -> status.value.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("不支持的日报状态"));
    }
}
