package com.leanmate.settings.dto;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.List;

public record UserSettingsRequest(
        Boolean mealReminderEnabled,
        @Size(max = 8) List<@Pattern(regexp = "^\\d{2}:\\d{2}$") String> mealReminderTimes,
        Boolean milestoneNoticeEnabled,
        Boolean autoSyncEnabled
) {
}
