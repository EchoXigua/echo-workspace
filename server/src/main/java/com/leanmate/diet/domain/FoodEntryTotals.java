package com.leanmate.diet.domain;

import java.math.BigDecimal;

public record FoodEntryTotals(
        int caloriesKcal,
        BigDecimal proteinG,
        BigDecimal fatG,
        BigDecimal carbsG
) {
}
