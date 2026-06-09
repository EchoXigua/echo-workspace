package com.leanmate.food.application;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.food.domain.FoodCatalogSource;
import com.leanmate.food.dto.CalculateFoodNutritionRequest;
import com.leanmate.food.dto.FoodDetailResponse;
import com.leanmate.food.dto.FoodNutritionCalculationResponse;
import com.leanmate.food.dto.FoodNutritionResponse;
import com.leanmate.food.dto.FoodPortionResponse;
import com.leanmate.food.dto.FoodSearchResultResponse;
import com.leanmate.food.repository.FoodAliasEntity;
import com.leanmate.food.repository.FoodAliasRepository;
import com.leanmate.food.repository.FoodCatalogEntity;
import com.leanmate.food.repository.FoodCatalogRepository;
import com.leanmate.food.repository.FoodPortionEntity;
import com.leanmate.food.repository.FoodPortionRepository;
import com.leanmate.user.application.CurrentUserApplicationService;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class FoodCatalogApplicationService {

    private static final int DEFAULT_SEARCH_LIMIT = 10;
    private static final int MAX_SEARCH_LIMIT = 50;
    private static final BigDecimal HUNDRED = new BigDecimal("100");

    private final CurrentUserApplicationService currentUserApplicationService;
    private final FoodCatalogRepository foodCatalogRepository;
    private final FoodAliasRepository foodAliasRepository;
    private final FoodPortionRepository foodPortionRepository;

    public FoodCatalogApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            FoodCatalogRepository foodCatalogRepository,
            FoodAliasRepository foodAliasRepository,
            FoodPortionRepository foodPortionRepository
    ) {
        this.currentUserApplicationService = currentUserApplicationService;
        this.foodCatalogRepository = foodCatalogRepository;
        this.foodAliasRepository = foodAliasRepository;
        this.foodPortionRepository = foodPortionRepository;
    }

    @Transactional(readOnly = true)
    public List<FoodSearchResultResponse> search(UUID userId, String query, Integer limit) {
        currentUserApplicationService.requireActiveUser(userId);
        String normalizedQuery = normalize(query);
        if (!StringUtils.hasText(normalizedQuery)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "q 不能为空");
        }

        int safeLimit = limit == null ? DEFAULT_SEARCH_LIMIT : Math.min(Math.max(limit, 1), MAX_SEARCH_LIMIT);
        return foodCatalogRepository.searchVerified(normalizedQuery, PageRequest.of(0, safeLimit))
                .stream()
                .map(this::toSearchResult)
                .toList();
    }

    @Transactional(readOnly = true)
    public FoodDetailResponse getDetail(UUID userId, UUID foodId) {
        currentUserApplicationService.requireActiveUser(userId);
        FoodCatalogEntity food = requireFood(foodId);
        List<String> aliases = foodAliasRepository.findByFoodIdOrderByAliasAsc(foodId)
                .stream()
                .map(FoodAliasEntity::getAlias)
                .toList();
        List<FoodPortionResponse> portions = foodPortionRepository.findByFoodIdOrderBySortOrderAsc(foodId)
                .stream()
                .map(this::toPortionResponse)
                .toList();
        return new FoodDetailResponse(
                food.getId(),
                food.getName(),
                food.getCategory(),
                food.getCaloriesPer100g(),
                food.getProteinPer100g(),
                food.getFatPer100g(),
                food.getCarbsPer100g(),
                FoodCatalogSource.fromValue(food.getSource()),
                food.getConfidence(),
                Boolean.TRUE.equals(food.getVerified()),
                aliases,
                portions);
    }

    @Transactional(readOnly = true)
    public FoodNutritionCalculationResponse calculate(
            UUID userId,
            CalculateFoodNutritionRequest request
    ) {
        currentUserApplicationService.requireActiveUser(userId);
        if (request.foodId() == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "foodId 不能为空");
        }
        if (request.weightG() == null && request.portionId() == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "weightG 和 portionId 至少传一个");
        }

        FoodCatalogEntity food = requireFood(request.foodId());
        BigDecimal weightG;
        String estimateBasis;
        if (request.weightG() != null) {
            validateWeight(request.weightG());
            weightG = request.weightG();
            estimateBasis = "weight";
        } else {
            FoodPortionEntity portion = foodPortionRepository
                    .findByIdAndFoodId(request.portionId(), request.foodId())
                    .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "份量不存在"));
            weightG = portion.getGramWeight();
            estimateBasis = "portion";
        }

        FoodNutritionResponse nutrition = calculateNutrition(food, weightG);
        return new FoodNutritionCalculationResponse(
                food.getId(),
                food.getName(),
                scale(weightG, 2),
                nutrition.caloriesKcal(),
                nutrition.proteinG(),
                nutrition.fatG(),
                nutrition.carbsG(),
                estimateBasis);
    }

    private FoodSearchResultResponse toSearchResult(FoodCatalogEntity food) {
        FoodPortionEntity defaultPortion = foodPortionRepository.findByFoodIdAndDefaultPortionTrue(food.getId())
                .orElse(null);
        FoodPortionResponse defaultPortionResponse = defaultPortion == null ? null : toPortionResponse(defaultPortion);
        FoodNutritionResponse estimatedNutrition = defaultPortion == null
                ? null
                : calculateNutrition(food, defaultPortion.getGramWeight());
        String estimateBasis = defaultPortion == null ? "per_100g" : "default_portion";
        String displayHint = defaultPortion == null
                ? "按每 100g 营养值展示，可填写重量"
                : "按 " + defaultPortion.getLabel() + " 估算，可修改重量";

        return new FoodSearchResultResponse(
                food.getId(),
                food.getName(),
                food.getCategory(),
                food.getCaloriesPer100g(),
                food.getProteinPer100g(),
                food.getFatPer100g(),
                food.getCarbsPer100g(),
                FoodCatalogSource.fromValue(food.getSource()),
                food.getConfidence(),
                Boolean.TRUE.equals(food.getVerified()),
                defaultPortionResponse,
                estimatedNutrition,
                estimateBasis,
                displayHint);
    }

    private FoodCatalogEntity requireFood(UUID foodId) {
        return foodCatalogRepository.findById(foodId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "食物不存在"));
    }

    private FoodPortionResponse toPortionResponse(FoodPortionEntity portion) {
        return new FoodPortionResponse(
                portion.getId(),
                portion.getLabel(),
                portion.getGramWeight(),
                Boolean.TRUE.equals(portion.getDefaultPortion()));
    }

    private FoodNutritionResponse calculateNutrition(FoodCatalogEntity food, BigDecimal weightG) {
        BigDecimal factor = weightG.divide(HUNDRED, 6, RoundingMode.HALF_UP);
        return new FoodNutritionResponse(
                new BigDecimal(food.getCaloriesPer100g()).multiply(factor).setScale(0, RoundingMode.HALF_UP).intValue(),
                scale(food.getProteinPer100g().multiply(factor), 2),
                scale(food.getFatPer100g().multiply(factor), 2),
                scale(food.getCarbsPer100g().multiply(factor), 2));
    }

    private BigDecimal scale(BigDecimal value, int scale) {
        return value.setScale(scale, RoundingMode.HALF_UP);
    }

    private void validateWeight(BigDecimal weightG) {
        if (weightG.compareTo(BigDecimal.ZERO) <= 0 || weightG.compareTo(new BigDecimal("10000")) > 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "weightG 必须大于 0 且不超过 10000g");
        }
    }

    private String normalize(String value) {
        if (value == null) {
            return "";
        }
        return value.trim().toLowerCase().replaceAll("\\s+", "");
    }
}
