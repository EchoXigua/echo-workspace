package com.leanmate.diet.dto;

import com.leanmate.diet.domain.MealType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

public record TextRecognitionRequest(
        @NotBlank @Size(max = 1000) String text,
        @NotNull MealType mealType,
        LocalDate mealDate
) {
}
