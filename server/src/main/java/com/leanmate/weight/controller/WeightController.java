package com.leanmate.weight.controller;

import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.weight.application.WeightApplicationService;
import com.leanmate.weight.dto.SaveWeightEntryRequest;
import com.leanmate.weight.dto.WeightEntryResponse;
import com.leanmate.weight.dto.WeightEntrySaveResultResponse;
import com.leanmate.weight.dto.WeightTrendResponse;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/weights")
public class WeightController {

    private final WeightApplicationService weightApplicationService;

    public WeightController(WeightApplicationService weightApplicationService) {
        this.weightApplicationService = weightApplicationService;
    }

    @GetMapping
    public ApiResponse<List<WeightEntryResponse>> listWeights(
            @RequestParam LocalDate startDate,
            @RequestParam LocalDate endDate
    ) {
        return ApiResponse.success(weightApplicationService.listWeights(
                CurrentUserContext.getRequired().userId(),
                startDate,
                endDate));
    }

    @GetMapping("/trend")
    public ApiResponse<WeightTrendResponse> getTrend(@RequestParam(required = false) Integer days) {
        return ApiResponse.success(weightApplicationService.getTrend(
                CurrentUserContext.getRequired().userId(),
                days));
    }

    @PostMapping
    public ApiResponse<WeightEntrySaveResultResponse> saveWeight(
            @Valid @RequestBody SaveWeightEntryRequest request
    ) {
        return ApiResponse.success(weightApplicationService.saveWeight(
                CurrentUserContext.getRequired().userId(),
                request));
    }
}
