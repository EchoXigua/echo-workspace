package com.leanmate.user.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;

public enum AuthProvider {
    APPLE("apple"),
    GOOGLE("google");

    private final String value;

    AuthProvider(String value) {
        this.value = value;
    }

    @JsonValue
    public String value() {
        return value;
    }

    @JsonCreator
    public static AuthProvider fromValue(String value) {
        return Arrays.stream(values())
                .filter(provider -> provider.value.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("不支持的登录方式"));
    }
}
