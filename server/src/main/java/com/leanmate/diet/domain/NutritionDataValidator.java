package com.leanmate.diet.domain;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.diet.dto.SaveFoodItemRequest;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class NutritionDataValidator {

    private static final int MAX_ITEM_CALORIES_KCAL = 5000;
    private static final BigDecimal MAX_WEIGHT_G = new BigDecimal("10000");
    private static final BigDecimal MAX_MACRO_G = new BigDecimal("1000");
    private static final BigDecimal MAX_KCAL_PER_100G = new BigDecimal("1000");
    private static final BigDecimal MACRO_CALORIES_ABSOLUTE_TOLERANCE = new BigDecimal("100");
    private static final BigDecimal MACRO_CALORIES_RELATIVE_TOLERANCE = new BigDecimal("0.45");

    public void validate(List<SaveFoodItemRequest> items) {
        if (items == null || items.isEmpty()) {
            throw invalid("items 不能为空");
        }
        items.forEach(this::validateItem);
    }

    private void validateItem(SaveFoodItemRequest item) {
        if (item == null) {
            throw invalid("食物项不能为空");
        }
        if (!StringUtils.hasText(item.name())) {
            throw invalid("食物名称不能为空");
        }
        if (item.name().trim().length() > 128) {
            throw invalid("食物名称长度不能超过 128");
        }
        if (item.quantityText() != null && item.quantityText().length() > 128) {
            throw invalid("quantityText 长度不能超过 128");
        }
        validateCalories(item.caloriesKcal());
        validateWeight(item.weightG());
        validateMacro(item.proteinG(), "proteinG");
        validateMacro(item.fatG(), "fatG");
        validateMacro(item.carbsG(), "carbsG");
        validateConfidence(item.confidence());
        validateCaloriesPer100g(item);
        validateMacroCaloriesConsistency(item);
    }

    private void validateCalories(Integer caloriesKcal) {
        if (caloriesKcal == null) {
            return;
        }
        if (caloriesKcal < 0) {
            throw invalid("caloriesKcal 不能小于 0");
        }
        if (caloriesKcal > MAX_ITEM_CALORIES_KCAL) {
            throw invalid("单个食物热量不能超过 5000 kcal");
        }
    }

    private void validateWeight(BigDecimal weightG) {
        if (weightG == null) {
            return;
        }
        if (weightG.compareTo(BigDecimal.ZERO) <= 0) {
            throw invalid("weightG 必须大于 0");
        }
        if (weightG.compareTo(MAX_WEIGHT_G) > 0) {
            throw invalid("weightG 不能超过 10000g");
        }
    }

    private void validateMacro(BigDecimal value, String fieldName) {
        if (value == null) {
            return;
        }
        if (value.signum() < 0) {
            throw invalid(fieldName + " 不能小于 0");
        }
        if (value.compareTo(MAX_MACRO_G) > 0) {
            throw invalid(fieldName + " 不能超过 1000g");
        }
    }

    private void validateConfidence(BigDecimal confidence) {
        if (confidence == null) {
            return;
        }
        if (confidence.signum() < 0 || confidence.compareTo(BigDecimal.ONE) > 0) {
            throw invalid("confidence 必须在 0 到 1 之间");
        }
    }

    private void validateCaloriesPer100g(SaveFoodItemRequest item) {
        if (item.caloriesKcal() == null || item.weightG() == null) {
            return;
        }
        BigDecimal caloriesPer100g = new BigDecimal(item.caloriesKcal())
                .multiply(new BigDecimal("100"))
                .divide(item.weightG(), 2, RoundingMode.HALF_UP);
        if (caloriesPer100g.compareTo(MAX_KCAL_PER_100G) > 0) {
            throw invalid("每 100g 热量超过合理范围");
        }
    }

    private void validateMacroCaloriesConsistency(SaveFoodItemRequest item) {
        if (item.caloriesKcal() == null) {
            return;
        }

        BigDecimal macroCalories = macroCalories(item);
        if (macroCalories.compareTo(BigDecimal.ZERO) == 0) {
            return;
        }

        BigDecimal calories = new BigDecimal(item.caloriesKcal());
        BigDecimal difference = macroCalories.subtract(calories).abs();
        BigDecimal tolerance = calories
                .multiply(MACRO_CALORIES_RELATIVE_TOLERANCE)
                .max(MACRO_CALORIES_ABSOLUTE_TOLERANCE);
        if (difference.compareTo(tolerance) > 0) {
            throw invalid("热量与蛋白质、脂肪、碳水估算值偏差过大");
        }
    }

    private BigDecimal macroCalories(SaveFoodItemRequest item) {
        return valueOrZero(item.proteinG()).multiply(new BigDecimal("4"))
                .add(valueOrZero(item.carbsG()).multiply(new BigDecimal("4")))
                .add(valueOrZero(item.fatG()).multiply(new BigDecimal("9")));
    }

    private BigDecimal valueOrZero(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    private BusinessException invalid(String message) {
        return new BusinessException(ErrorCode.BAD_REQUEST, message);
    }
}
