package com.leanmate.ai.dto;

import java.math.BigDecimal;

public record DietRecognitionItem(
        String name,
        String quantityText,
        BigDecimal weightG,
        Integer caloriesKcal,
        BigDecimal proteinG,
        BigDecimal fatG,
        BigDecimal carbsG,
        BigDecimal confidence
) {
}
