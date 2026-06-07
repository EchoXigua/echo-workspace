package com.leanmate.ai.dto;

import java.time.LocalDate;

public record DailyReportStreakInput(
        int currentDays,
        int longestDays,
        LocalDate lastActiveDate
) {
}
