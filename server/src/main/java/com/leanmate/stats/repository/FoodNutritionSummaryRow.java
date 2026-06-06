package com.leanmate.stats.repository;

import java.math.BigDecimal;

public interface FoodNutritionSummaryRow {

    Long getFoodEntryCount();

    Integer getCaloriesKcal();

    BigDecimal getProteinG();

    BigDecimal getFatG();

    BigDecimal getCarbsG();
}
