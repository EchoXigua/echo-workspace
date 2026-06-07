package com.leanmate.retention.controller;

import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.retention.application.RetentionApplicationService;
import com.leanmate.retention.dto.StreakResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/retention")
public class RetentionController {

    private final RetentionApplicationService retentionApplicationService;

    public RetentionController(RetentionApplicationService retentionApplicationService) {
        this.retentionApplicationService = retentionApplicationService;
    }

    @GetMapping("/streak")
    public ApiResponse<StreakResponse> getStreak() {
        return ApiResponse.success(retentionApplicationService.getStreak(
                CurrentUserContext.getRequired().userId()));
    }
}
