package com.leanmate.food.seed;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.leanmate.food.repository.FoodAliasEntity;
import com.leanmate.food.repository.FoodAliasRepository;
import com.leanmate.food.repository.FoodCatalogEntity;
import com.leanmate.food.repository.FoodCatalogRepository;
import com.leanmate.food.repository.FoodPortionEntity;
import com.leanmate.food.repository.FoodPortionRepository;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.DefaultResourceLoader;

class FoodCatalogSeedServiceTests {

    private FoodCatalogRepository foodCatalogRepository;
    private FoodAliasRepository foodAliasRepository;
    private FoodPortionRepository foodPortionRepository;
    private FoodCatalogSeedService foodCatalogSeedService;

    @BeforeEach
    void setUp() {
        foodCatalogRepository = mock(FoodCatalogRepository.class);
        foodAliasRepository = mock(FoodAliasRepository.class);
        foodPortionRepository = mock(FoodPortionRepository.class);
        foodCatalogSeedService = new FoodCatalogSeedService(
                new DefaultResourceLoader(),
                foodCatalogRepository,
                foodAliasRepository,
                foodPortionRepository);

        when(foodCatalogRepository.findById(any())).thenReturn(Optional.empty());
        when(foodCatalogRepository.save(any(FoodCatalogEntity.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(foodAliasRepository.saveAll(org.mockito.ArgumentMatchers.<Iterable<FoodAliasEntity>>any()))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(foodPortionRepository.saveAll(org.mockito.ArgumentMatchers.<Iterable<FoodPortionEntity>>any()))
                .thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void importClasspathSeedFiles() {
        foodCatalogSeedService.importSeed("classpath:db/seed/food-catalog");

        verify(foodCatalogRepository, times(20)).save(any(FoodCatalogEntity.class));
        verify(foodCatalogRepository).save(argThat(food ->
                "苹果".equals(food.getName())
                        && food.getCaloriesPer100g() == 52
                        && "curated".equals(food.getSource())));
        verify(foodAliasRepository, times(20)).deleteByFoodId(any());
        verify(foodPortionRepository, times(20)).deleteByFoodId(any());
        verify(foodAliasRepository, times(20))
                .saveAll(org.mockito.ArgumentMatchers.<Iterable<FoodAliasEntity>>any());
        verify(foodPortionRepository, times(20))
                .saveAll(org.mockito.ArgumentMatchers.<Iterable<FoodPortionEntity>>any());
    }
}
