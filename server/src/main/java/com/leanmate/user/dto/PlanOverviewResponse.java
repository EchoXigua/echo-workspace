package com.leanmate.user.dto;

public record PlanOverviewResponse(
        boolean profileCompleted,
        String displayName,
        PlanOverviewProfileResponse profile,
        PlanOverviewGoalResponse goal,
        PlanOverviewWeightTrendResponse weightTrend,
        PlanOverviewCalorieAdjustmentResponse calorieAdjustment
) {
}
