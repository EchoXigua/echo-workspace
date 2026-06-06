package com.leanmate.user.controller;

import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.dto.CurrentUserResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/me")
public class MeController {

    private final CurrentUserApplicationService currentUserApplicationService;

    public MeController(CurrentUserApplicationService currentUserApplicationService) {
        this.currentUserApplicationService = currentUserApplicationService;
    }

    @GetMapping
    public ApiResponse<CurrentUserResponse> getCurrentUser() {
        return ApiResponse.success(
                currentUserApplicationService.getCurrentUser(CurrentUserContext.getRequired().userId()));
    }
}
