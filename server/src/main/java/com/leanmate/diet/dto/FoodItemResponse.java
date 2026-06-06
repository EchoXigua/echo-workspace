package com.leanmate.diet.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record FoodItemResponse(
        UUID id,
        String name,
        String quantityText,
        BigDecimal weightG,
        Integer caloriesKcal,
        BigDecimal proteinG,
        BigDecimal fatG,
        BigDecimal carbsG,
        BigDecimal confidence,
        boolean userEdited
) {
}
