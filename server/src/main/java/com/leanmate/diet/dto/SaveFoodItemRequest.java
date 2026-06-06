package com.leanmate.diet.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.UUID;

public record SaveFoodItemRequest(
        UUID id,
        @NotBlank @Size(max = 128) String name,
        @Size(max = 128) String quantityText,
        @DecimalMin("0.0") BigDecimal weightG,
        @Min(0) Integer caloriesKcal,
        @DecimalMin("0.0") BigDecimal proteinG,
        @DecimalMin("0.0") BigDecimal fatG,
        @DecimalMin("0.0") BigDecimal carbsG,
        @DecimalMin("0.0") @DecimalMax("1.0") BigDecimal confidence,
        Boolean userEdited
) {
}
