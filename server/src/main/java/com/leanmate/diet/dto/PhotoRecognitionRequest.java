package com.leanmate.diet.dto;

import com.leanmate.diet.domain.MealType;
import java.time.LocalDate;

public record PhotoRecognitionRequest(
        String originalFilename,
        String contentType,
        long imageSizeBytes,
        MealType mealType,
        LocalDate mealDate,
        String note
) {
}
