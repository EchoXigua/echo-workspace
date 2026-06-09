package com.leanmate.diet.dto;

import java.util.UUID;

public record LocalDietEntrySyncFailureResponse(
        UUID clientLocalId,
        String code,
        String message
) {
}
