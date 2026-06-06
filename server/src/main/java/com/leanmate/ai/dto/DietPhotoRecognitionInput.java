package com.leanmate.ai.dto;

import com.leanmate.diet.domain.MealType;
import java.time.LocalDate;
import java.util.UUID;

public record DietPhotoRecognitionInput(
        UUID taskId,
        UUID userId,
        LocalDate mealDate,
        MealType mealType,
        String note,
        String objectKey,
        String contentType,
        long imageSizeBytes
) {
}
