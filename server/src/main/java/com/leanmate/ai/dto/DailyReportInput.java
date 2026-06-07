package com.leanmate.ai.dto;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record DailyReportInput(
        UUID userId,
        LocalDate reportDate,
        DailyReportProfileInput profile,
        DailyReportGoalInput goal,
        DailyReportSnapshotInput snapshot,
        List<DailyReportFoodEntryInput> foodEntries,
        DailyReportWeightEntryInput weightEntry,
        DailyReportStreakInput streak
) {
}
