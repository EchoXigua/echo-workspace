package com.leanmate.sync.controller;

import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.sync.application.SyncApplicationService;
import com.leanmate.sync.dto.SyncLocalRequest;
import com.leanmate.sync.dto.SyncLocalResultResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/sync")
public class SyncController {

    private final SyncApplicationService syncApplicationService;

    public SyncController(SyncApplicationService syncApplicationService) {
        this.syncApplicationService = syncApplicationService;
    }

    @PostMapping("/local")
    public ApiResponse<SyncLocalResultResponse> syncLocal(@Valid @RequestBody SyncLocalRequest request) {
        return ApiResponse.success(syncApplicationService.syncLocal(
                CurrentUserContext.getRequired().userId(),
                request));
    }
}
