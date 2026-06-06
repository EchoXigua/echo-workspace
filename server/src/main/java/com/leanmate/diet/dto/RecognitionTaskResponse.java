package com.leanmate.diet.dto;

import com.leanmate.diet.domain.FoodEntrySourceType;
import com.leanmate.diet.domain.MealType;
import com.leanmate.diet.domain.RecognitionTaskStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record RecognitionTaskResponse(
        UUID id,
        FoodEntrySourceType sourceType,
        LocalDate mealDate,
        MealType mealType,
        RecognitionTaskStatus status,
        FoodEntryDraftResponse draftEntry,
        String errorCode,
        String errorMessage,
        Instant createdAt,
        Instant finishedAt
) {
}
