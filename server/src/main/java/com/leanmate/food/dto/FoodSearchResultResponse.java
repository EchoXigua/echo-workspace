package com.leanmate.food.dto;

import com.leanmate.food.domain.FoodCatalogSource;
import java.math.BigDecimal;
import java.util.UUID;

public record FoodSearchResultResponse(
        UUID id,
        String name,
        String category,
        int caloriesPer100g,
        BigDecimal proteinPer100g,
        BigDecimal fatPer100g,
        BigDecimal carbsPer100g,
        FoodCatalogSource source,
        BigDecimal confidence,
        boolean verified,
        FoodPortionResponse defaultPortion,
        FoodNutritionResponse estimatedNutrition,
        String estimateBasis,
        String displayHint
) {
}
