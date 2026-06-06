package com.leanmate.diet.dto;

import com.leanmate.diet.domain.FoodEntrySourceType;
import com.leanmate.diet.domain.MealType;
import java.time.LocalDate;
import java.util.List;

public record FoodEntryDraftResponse(
        LocalDate mealDate,
        MealType mealType,
        FoodEntrySourceType sourceType,
        List<FoodItemResponse> items
) {
}
