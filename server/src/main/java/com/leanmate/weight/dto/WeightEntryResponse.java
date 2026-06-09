package com.leanmate.weight.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record WeightEntryResponse(
        UUID id,
        UUID clientLocalId,
        LocalDate recordDate,
        BigDecimal weightKg,
        String note,
        Instant createdAt
) {
}
