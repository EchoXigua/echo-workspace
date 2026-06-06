package com.leanmate.diet.dto;

import com.leanmate.diet.domain.FoodEntrySourceType;
import com.leanmate.diet.domain.FoodEntryStatus;
import com.leanmate.diet.domain.MealType;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record FoodEntryResponse(
        UUID id,
        UUID recognitionTaskId,
        LocalDate mealDate,
        MealType mealType,
        FoodEntrySourceType sourceType,
        String rawText,
        String imageUrl,
        FoodEntryStatus status,
        int totalCaloriesKcal,
        BigDecimal totalProteinG,
        BigDecimal totalFatG,
        BigDecimal totalCarbsG,
        List<FoodItemResponse> items,
        Instant createdAt
) {
}
