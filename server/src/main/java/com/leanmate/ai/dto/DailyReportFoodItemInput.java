package com.leanmate.ai.dto;

import java.math.BigDecimal;

public record DailyReportFoodItemInput(
        String name,
        String quantityText,
        BigDecimal weightG,
        Integer caloriesKcal,
        BigDecimal proteinG,
        BigDecimal fatG,
        BigDecimal carbsG
) {
}
