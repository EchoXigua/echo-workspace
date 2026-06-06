package com.leanmate.stats.repository;

import java.util.UUID;

public interface FoodEntrySummaryRow {

    UUID getId();

    String getMealType();

    Integer getTotalCaloriesKcal();

    String getItemNamesText();
}
