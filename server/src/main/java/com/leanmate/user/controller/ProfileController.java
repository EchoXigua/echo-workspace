package com.leanmate.user.controller;

import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.user.application.UserProfileApplicationService;
import com.leanmate.user.dto.CalorieTargetSuggestionResponse;
import com.leanmate.user.dto.PlanOverviewResponse;
import com.leanmate.user.dto.ProfilePayload;
import com.leanmate.user.dto.SaveUserProfileRequest;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/profile")
public class ProfileController {

    private final UserProfileApplicationService userProfileApplicationService;

    public ProfileController(UserProfileApplicationService userProfileApplicationService) {
        this.userProfileApplicationService = userProfileApplicationService;
    }

    @GetMapping
    public ApiResponse<ProfilePayload> getProfile() {
        return ApiResponse.success(
                userProfileApplicationService.getProfile(CurrentUserContext.getRequired().userId()));
    }

    @GetMapping("/calorie-target-suggestion")
    public ApiResponse<CalorieTargetSuggestionResponse> getCalorieTargetSuggestion() {
        return ApiResponse.success(userProfileApplicationService.getCalorieTargetSuggestion(
                CurrentUserContext.getRequired().userId()));
    }

    @GetMapping("/plan-overview")
    public ApiResponse<PlanOverviewResponse> getPlanOverview() {
        return ApiResponse.success(userProfileApplicationService.getPlanOverview(
                CurrentUserContext.getRequired().userId()));
    }

    @PutMapping
    public ApiResponse<ProfilePayload> saveProfile(@Valid @RequestBody SaveUserProfileRequest request) {
        return ApiResponse.success(
                userProfileApplicationService.saveProfile(CurrentUserContext.getRequired().userId(), request));
    }
}
