package com.leanmate.food.seed;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.util.StringUtils;

@ConfigurationProperties(prefix = "leanmate.food-catalog.seed")
public record FoodCatalogSeedProperties(
        Boolean enabled,
        String location
) {
    private static final String DEFAULT_LOCATION = "classpath:db/seed/food-catalog";

    public boolean isEnabled() {
        return enabled == null || enabled;
    }

    public String safeLocation() {
        return StringUtils.hasText(location) ? location : DEFAULT_LOCATION;
    }
}
