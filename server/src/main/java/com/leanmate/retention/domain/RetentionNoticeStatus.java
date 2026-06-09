package com.leanmate.retention.domain;

public enum RetentionNoticeStatus {
    PENDING("pending"),
    DISMISSED("dismissed");

    private final String value;

    RetentionNoticeStatus(String value) {
        this.value = value;
    }

    public String value() {
        return value;
    }
}
