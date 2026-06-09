package com.leanmate.food.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.food.dto.CalculateFoodNutritionRequest;
import com.leanmate.food.dto.FoodNutritionCalculationResponse;
import com.leanmate.food.dto.FoodSearchResultResponse;
import com.leanmate.food.repository.FoodAliasRepository;
import com.leanmate.food.repository.FoodCatalogEntity;
import com.leanmate.food.repository.FoodCatalogRepository;
import com.leanmate.food.repository.FoodPortionEntity;
import com.leanmate.food.repository.FoodPortionRepository;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.repository.UserEntity;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Pageable;

class FoodCatalogApplicationServiceTests {

    private static final UUID USER_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID FOOD_ID = UUID.fromString("10000000-0000-0000-0000-000000000011");
    private static final UUID PORTION_ID = UUID.fromString("20000000-0000-0000-0000-000000000011");

    private FoodCatalogRepository foodCatalogRepository;
    private FoodPortionRepository foodPortionRepository;
    private FoodCatalogApplicationService foodCatalogApplicationService;

    @BeforeEach
    void setUp() {
        CurrentUserApplicationService currentUserApplicationService = mock(CurrentUserApplicationService.class);
        foodCatalogRepository = mock(FoodCatalogRepository.class);
        FoodAliasRepository foodAliasRepository = mock(FoodAliasRepository.class);
        foodPortionRepository = mock(FoodPortionRepository.class);
        foodCatalogApplicationService = new FoodCatalogApplicationService(
                currentUserApplicationService,
                foodCatalogRepository,
                foodAliasRepository,
                foodPortionRepository);

        when(currentUserApplicationService.requireActiveUser(USER_ID)).thenReturn(new UserEntity());
    }

    @Test
    void searchReturnsDefaultPortionEstimatedNutrition() {
        FoodCatalogEntity apple = apple();
        FoodPortionEntity portion = applePortion();
        when(foodCatalogRepository.searchVerified(eq("苹果"), any(Pageable.class))).thenReturn(List.of(apple));
        when(foodPortionRepository.findByFoodIdAndDefaultPortionTrue(FOOD_ID)).thenReturn(Optional.of(portion));

        List<FoodSearchResultResponse> response = foodCatalogApplicationService.search(USER_ID, " 苹果 ", 10);

        assertThat(response).hasSize(1);
        FoodSearchResultResponse result = response.get(0);
        assertThat(result.name()).isEqualTo("苹果");
        assertThat(result.defaultPortion().label()).isEqualTo("1个中等大小");
        assertThat(result.estimatedNutrition().caloriesKcal()).isEqualTo(94);
        assertThat(result.estimatedNutrition().carbsG()).isEqualByComparingTo("24.84");
        assertThat(result.estimateBasis()).isEqualTo("default_portion");
    }

    @Test
    void calculateByWeight() {
        when(foodCatalogRepository.findById(FOOD_ID)).thenReturn(Optional.of(apple()));

        FoodNutritionCalculationResponse response = foodCatalogApplicationService.calculate(
                USER_ID,
                new CalculateFoodNutritionRequest(FOOD_ID, new BigDecimal("90"), null));

        assertThat(response.caloriesKcal()).isEqualTo(47);
        assertThat(response.weightG()).isEqualByComparingTo("90.00");
        assertThat(response.estimateBasis()).isEqualTo("weight");
    }

    @Test
    void calculateByPortion() {
        when(foodCatalogRepository.findById(FOOD_ID)).thenReturn(Optional.of(apple()));
        when(foodPortionRepository.findByIdAndFoodId(PORTION_ID, FOOD_ID)).thenReturn(Optional.of(applePortion()));

        FoodNutritionCalculationResponse response = foodCatalogApplicationService.calculate(
                USER_ID,
                new CalculateFoodNutritionRequest(FOOD_ID, null, PORTION_ID));

        assertThat(response.caloriesKcal()).isEqualTo(94);
        assertThat(response.weightG()).isEqualByComparingTo("180.00");
        assertThat(response.estimateBasis()).isEqualTo("portion");
    }

    @Test
    void rejectCalculateWithoutWeightOrPortion() {
        assertThatThrownBy(() -> foodCatalogApplicationService.calculate(
                USER_ID,
                new CalculateFoodNutritionRequest(FOOD_ID, null, null)))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.BAD_REQUEST);
    }

    private FoodCatalogEntity apple() {
        FoodCatalogEntity food = new FoodCatalogEntity();
        food.setId(FOOD_ID);
        food.setName("苹果");
        food.setNormalizedName("苹果");
        food.setCategory("fruit");
        food.setCaloriesPer100g(52);
        food.setProteinPer100g(new BigDecimal("0.30"));
        food.setFatPer100g(new BigDecimal("0.20"));
        food.setCarbsPer100g(new BigDecimal("13.80"));
        food.setSource("curated");
        food.setConfidence(new BigDecimal("1.0000"));
        food.setVerified(true);
        food.setLocale("zh-CN");
        return food;
    }

    private FoodPortionEntity applePortion() {
        FoodPortionEntity portion = new FoodPortionEntity();
        portion.setId(PORTION_ID);
        portion.setFoodId(FOOD_ID);
        portion.setLabel("1个中等大小");
        portion.setGramWeight(new BigDecimal("180"));
        portion.setDefaultPortion(true);
        portion.setSortOrder(0);
        return portion;
    }
}
