package com.leanmate.diet.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;

public enum RecognitionTaskStatus {
    PENDING("pending"),
    RUNNING("running"),
    SUCCEEDED("succeeded"),
    FAILED("failed");

    private final String value;

    RecognitionTaskStatus(String value) {
        this.value = value;
    }

    @JsonValue
    public String value() {
        return value;
    }

    @JsonCreator
    public static RecognitionTaskStatus fromValue(String value) {
        return Arrays.stream(values())
                .filter(status -> status.value.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("不支持的任务状态"));
    }
}
