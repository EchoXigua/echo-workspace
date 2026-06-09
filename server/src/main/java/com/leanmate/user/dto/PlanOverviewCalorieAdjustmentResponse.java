package com.leanmate.user.dto;

public record PlanOverviewCalorieAdjustmentResponse(
        String action,
        int suggestedDailyCalorieTargetKcal,
        String message
) {
}
