package com.leanmate.diet.controller;

import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.diet.application.DietEntryApplicationService;
import com.leanmate.diet.dto.FoodEntryResponse;
import com.leanmate.diet.dto.FoodEntrySaveResultResponse;
import com.leanmate.diet.dto.SaveFoodEntryRequest;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/diet/entries")
public class DietEntryController {

    private final DietEntryApplicationService dietEntryApplicationService;

    public DietEntryController(DietEntryApplicationService dietEntryApplicationService) {
        this.dietEntryApplicationService = dietEntryApplicationService;
    }

    @GetMapping
    public ApiResponse<List<FoodEntryResponse>> listEntries(@RequestParam LocalDate date) {
        return ApiResponse.success(dietEntryApplicationService.listEntries(
                CurrentUserContext.getRequired().userId(),
                date));
    }

    @PostMapping
    public ApiResponse<FoodEntrySaveResultResponse> createEntry(
            @Valid @RequestBody SaveFoodEntryRequest request
    ) {
        return ApiResponse.success(dietEntryApplicationService.createEntry(
                CurrentUserContext.getRequired().userId(),
                request));
    }

    @PutMapping("/{entryId}")
    public ApiResponse<FoodEntrySaveResultResponse> updateEntry(
            @PathVariable UUID entryId,
            @Valid @RequestBody SaveFoodEntryRequest request
    ) {
        return ApiResponse.success(dietEntryApplicationService.updateEntry(
                CurrentUserContext.getRequired().userId(),
                entryId,
                request));
    }

    @DeleteMapping("/{entryId}")
    public ApiResponse<Void> deleteEntry(@PathVariable UUID entryId) {
        dietEntryApplicationService.deleteEntry(CurrentUserContext.getRequired().userId(), entryId);
        return ApiResponse.success();
    }
}
