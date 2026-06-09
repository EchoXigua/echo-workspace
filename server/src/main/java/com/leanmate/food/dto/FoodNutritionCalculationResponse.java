package com.leanmate.food.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record FoodNutritionCalculationResponse(
        UUID foodId,
        String name,
        BigDecimal weightG,
        int caloriesKcal,
        BigDecimal proteinG,
        BigDecimal fatG,
        BigDecimal carbsG,
        String estimateBasis
) {
}
