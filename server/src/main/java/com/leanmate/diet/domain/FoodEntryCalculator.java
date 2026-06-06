package com.leanmate.diet.domain;

import com.leanmate.diet.dto.SaveFoodItemRequest;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class FoodEntryCalculator {

    private static final BigDecimal ZERO = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);

    public FoodEntryTotals calculate(List<SaveFoodItemRequest> items) {
        int caloriesKcal = items.stream()
                .map(SaveFoodItemRequest::caloriesKcal)
                .mapToInt(value -> value == null ? 0 : value)
                .sum();
        BigDecimal proteinG = sumNutrition(items.stream()
                .map(SaveFoodItemRequest::proteinG)
                .toList());
        BigDecimal fatG = sumNutrition(items.stream()
                .map(SaveFoodItemRequest::fatG)
                .toList());
        BigDecimal carbsG = sumNutrition(items.stream()
                .map(SaveFoodItemRequest::carbsG)
                .toList());
        return new FoodEntryTotals(caloriesKcal, proteinG, fatG, carbsG);
    }

    private BigDecimal sumNutrition(List<BigDecimal> values) {
        return values.stream()
                .filter(value -> value != null)
                .reduce(ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);
    }
}
