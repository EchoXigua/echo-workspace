package com.leanmate.food.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import java.math.BigDecimal;
import java.util.UUID;

public record CalculateFoodNutritionRequest(
        UUID foodId,
        @DecimalMin(value = "0.0", inclusive = false) @DecimalMax("10000.0") BigDecimal weightG,
        UUID portionId
) {
}
