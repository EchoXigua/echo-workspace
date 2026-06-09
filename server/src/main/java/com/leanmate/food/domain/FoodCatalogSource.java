package com.leanmate.food.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;

public enum FoodCatalogSource {
    CURATED("curated"),
    USDA("usda"),
    OPEN_FOOD_FACTS("open_food_facts"),
    VENDOR("vendor"),
    AI_ESTIMATED("ai_estimated");

    private final String value;

    FoodCatalogSource(String value) {
        this.value = value;
    }

    @JsonValue
    public String value() {
        return value;
    }

    @JsonCreator
    public static FoodCatalogSource fromValue(String value) {
        return Arrays.stream(values())
                .filter(source -> source.value.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("不支持的食物库来源"));
    }
}
