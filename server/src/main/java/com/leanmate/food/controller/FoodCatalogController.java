package com.leanmate.food.controller;

import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.food.application.FoodCatalogApplicationService;
import com.leanmate.food.dto.CalculateFoodNutritionRequest;
import com.leanmate.food.dto.FoodDetailResponse;
import com.leanmate.food.dto.FoodNutritionCalculationResponse;
import com.leanmate.food.dto.FoodSearchResultResponse;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/foods")
public class FoodCatalogController {

    private final FoodCatalogApplicationService foodCatalogApplicationService;

    public FoodCatalogController(FoodCatalogApplicationService foodCatalogApplicationService) {
        this.foodCatalogApplicationService = foodCatalogApplicationService;
    }

    @GetMapping("/search")
    public ApiResponse<List<FoodSearchResultResponse>> search(
            @RequestParam("q") String query,
            @RequestParam(required = false) Integer limit
    ) {
        return ApiResponse.success(foodCatalogApplicationService.search(
                CurrentUserContext.getRequired().userId(),
                query,
                limit));
    }

    @GetMapping("/{foodId}")
    public ApiResponse<FoodDetailResponse> getDetail(@PathVariable UUID foodId) {
        return ApiResponse.success(foodCatalogApplicationService.getDetail(
                CurrentUserContext.getRequired().userId(),
                foodId));
    }

    @PostMapping("/calculate")
    public ApiResponse<FoodNutritionCalculationResponse> calculate(
            @Valid @RequestBody CalculateFoodNutritionRequest request
    ) {
        return ApiResponse.success(foodCatalogApplicationService.calculate(
                CurrentUserContext.getRequired().userId(),
                request));
    }
}
