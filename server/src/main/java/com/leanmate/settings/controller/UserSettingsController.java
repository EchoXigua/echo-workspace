package com.leanmate.settings.controller;

import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.settings.application.UserSettingsApplicationService;
import com.leanmate.settings.dto.UserSettingsRequest;
import com.leanmate.settings.dto.UserSettingsResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/settings")
public class UserSettingsController {

    private final UserSettingsApplicationService userSettingsApplicationService;

    public UserSettingsController(UserSettingsApplicationService userSettingsApplicationService) {
        this.userSettingsApplicationService = userSettingsApplicationService;
    }

    @GetMapping
    public ApiResponse<UserSettingsResponse> getSettings() {
        return ApiResponse.success(userSettingsApplicationService.getSettings(
                CurrentUserContext.getRequired().userId()));
    }

    @PutMapping
    public ApiResponse<UserSettingsResponse> saveSettings(@Valid @RequestBody UserSettingsRequest request) {
        return ApiResponse.success(userSettingsApplicationService.saveSettings(
                CurrentUserContext.getRequired().userId(),
                request));
    }
}
