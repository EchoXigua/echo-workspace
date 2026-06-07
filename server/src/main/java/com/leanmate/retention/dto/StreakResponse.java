package com.leanmate.retention.dto;

import java.time.LocalDate;
import java.util.List;

public record StreakResponse(
        int currentDays,
        int longestDays,
        LocalDate lastActiveDate,
        List<StreakMilestoneResponse> milestones
) {
}
