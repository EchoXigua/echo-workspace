package com.leanmate.retention.dto;

import java.time.Instant;

public record StreakMilestoneResponse(
        int days,
        boolean achieved,
        Instant achievedAt
) {
}
