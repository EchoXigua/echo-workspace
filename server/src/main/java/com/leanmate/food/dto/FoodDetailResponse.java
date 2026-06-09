package com.leanmate.food.dto;

import com.leanmate.food.domain.FoodCatalogSource;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record FoodDetailResponse(
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
        List<String> aliases,
        List<FoodPortionResponse> portions
) {
}
