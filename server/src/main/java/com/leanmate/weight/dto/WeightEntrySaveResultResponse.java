package com.leanmate.weight.dto;

import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;

public record WeightEntrySaveResultResponse(
        WeightEntryResponse entry,
        DailyNutritionSnapshotResponse today
) {
}
