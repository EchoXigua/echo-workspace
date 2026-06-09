package com.leanmate.food.dto;

import java.math.BigDecimal;

public record FoodNutritionResponse(
        int caloriesKcal,
        BigDecimal proteinG,
        BigDecimal fatG,
        BigDecimal carbsG
) {
}
