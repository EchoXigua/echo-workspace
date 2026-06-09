package com.leanmate.diet.dto;

import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import java.util.List;
import java.util.UUID;

public record SyncLocalDietEntriesResultResponse(
        List<FoodEntryResponse> importedEntries,
        List<UUID> skippedClientLocalIds,
        List<LocalDietEntrySyncFailureResponse> failedItems,
        List<DailyNutritionSnapshotResponse> snapshots
) {
}
