package com.leanmate.diet.dto;

import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;

public record FoodEntrySaveResultResponse(
        FoodEntryResponse entry,
        DailyNutritionSnapshotResponse today
) {
}
