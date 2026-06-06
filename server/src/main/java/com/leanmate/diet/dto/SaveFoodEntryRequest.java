package com.leanmate.diet.dto;

import com.leanmate.diet.domain.FoodEntrySourceType;
import com.leanmate.diet.domain.MealType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record SaveFoodEntryRequest(
        UUID recognitionTaskId,
        @NotNull LocalDate mealDate,
        @NotNull MealType mealType,
        @NotNull FoodEntrySourceType sourceType,
        @Size(max = 1000) String rawText,
        String imageUrl,
        @NotEmpty @Valid List<SaveFoodItemRequest> items
) {
}
