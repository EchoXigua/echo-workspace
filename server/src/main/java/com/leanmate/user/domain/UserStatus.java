package com.leanmate.user.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;

public enum UserStatus {
    ACTIVE("active"),
    DISABLED("disabled"),
    DELETED("deleted");

    private final String value;

    UserStatus(String value) {
        this.value = value;
    }

    @JsonValue
    public String value() {
        return value;
    }

    @JsonCreator
    public static UserStatus fromValue(String value) {
        return Arrays.stream(values())
                .filter(status -> status.value.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("不支持的用户状态"));
    }
}
