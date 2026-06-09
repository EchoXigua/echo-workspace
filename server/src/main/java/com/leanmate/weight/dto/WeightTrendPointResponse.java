package com.leanmate.weight.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.math.BigDecimal;
import java.time.LocalDate;

public record WeightTrendPointResponse(
        LocalDate date,
        BigDecimal weightKg,
        @JsonProperty("isToday") boolean isToday
) {
}
