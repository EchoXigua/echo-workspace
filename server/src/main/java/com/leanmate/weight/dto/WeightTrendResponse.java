package com.leanmate.weight.dto;

import com.leanmate.weight.domain.WeightTrendDirection;
import java.math.BigDecimal;
import java.util.List;

public record WeightTrendResponse(
        int windowDays,
        BigDecimal targetWeightKg,
        BigDecimal startWeightKg,
        BigDecimal latestWeightKg,
        BigDecimal changeKg,
        WeightTrendDirection direction,
        List<WeightTrendPointResponse> points
) {
}
