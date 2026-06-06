package com.leanmate.ai.dto;

import com.leanmate.diet.domain.MealType;
import java.time.LocalDate;
import java.util.UUID;

public record DietTextRecognitionInput(
        UUID taskId,
        UUID userId,
        LocalDate mealDate,
        MealType mealType,
        String text
) {
}
