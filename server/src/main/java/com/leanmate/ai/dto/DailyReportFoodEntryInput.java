package com.leanmate.ai.dto;

import java.time.LocalDate;
import java.util.List;

public record DailyReportFoodEntryInput(
        LocalDate mealDate,
        String mealType,
        int caloriesKcal,
        List<DailyReportFoodItemInput> items
) {
}
