package com.leanmate.diet.dto;

import java.time.Instant;
import java.util.UUID;

public record LocalDietEntrySyncItemRequest(
        UUID clientLocalId,
        SaveFoodEntryRequest entry,
        Instant createdAt,
        Instant updatedAt
) {
}
