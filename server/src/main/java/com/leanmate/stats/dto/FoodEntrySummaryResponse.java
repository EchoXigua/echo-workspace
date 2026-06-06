package com.leanmate.stats.dto;

import java.util.List;
import java.util.UUID;

public record FoodEntrySummaryResponse(
        UUID id,
        String mealType,
        int totalCaloriesKcal,
        List<String> itemNames
) {
}
