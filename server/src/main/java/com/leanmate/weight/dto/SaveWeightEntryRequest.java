package com.leanmate.weight.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;

public record SaveWeightEntryRequest(
        @NotNull LocalDate recordDate,
        @NotNull @DecimalMin("20.0") @DecimalMax("300.0") BigDecimal weightKg,
        @Size(max = 500) String note
) {
}
