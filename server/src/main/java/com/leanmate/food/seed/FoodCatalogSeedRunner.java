package com.leanmate.food.seed;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class FoodCatalogSeedRunner implements ApplicationRunner {

    private final FoodCatalogSeedProperties properties;
    private final FoodCatalogSeedService foodCatalogSeedService;

    public FoodCatalogSeedRunner(
            FoodCatalogSeedProperties properties,
            FoodCatalogSeedService foodCatalogSeedService
    ) {
        this.properties = properties;
        this.foodCatalogSeedService = foodCatalogSeedService;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (properties.isEnabled()) {
            foodCatalogSeedService.importSeed(properties.safeLocation());
        }
    }
}
