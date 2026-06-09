package com.leanmate.retention.dto;

import java.time.Instant;
import java.util.UUID;

public record RetentionNoticeResponse(
        UUID id,
        String type,
        String title,
        String message,
        int currentValue,
        Integer previousValue,
        Integer nextValue,
        Instant triggeredAt
) {
}
