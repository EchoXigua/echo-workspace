package com.leanmate.food.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record FoodPortionResponse(
        UUID id,
        String label,
        BigDecimal gramWeight,
        boolean defaultPortion
) {
}
