package com.leanmate.settings.dto;

import java.util.List;

public record UserSettingsResponse(
        boolean mealReminderEnabled,
        List<String> mealReminderTimes,
        boolean milestoneNoticeEnabled,
        boolean autoSyncEnabled
) {
}
