package com.leanmate.user.dto;

import com.leanmate.weight.domain.WeightTrendDirection;
import java.math.BigDecimal;

public record PlanOverviewWeightTrendResponse(
        int windowDays,
        BigDecimal startWeightKg,
        BigDecimal latestWeightKg,
        BigDecimal changeKg,
        WeightTrendDirection direction
) {
}
