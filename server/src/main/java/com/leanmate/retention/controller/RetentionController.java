package com.leanmate.retention.controller;

import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.retention.application.RetentionApplicationService;
import com.leanmate.retention.dto.RetentionNoticeResponse;
import com.leanmate.retention.dto.StreakResponse;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
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

    @GetMapping("/milestone-notices")
    public ApiResponse<List<RetentionNoticeResponse>> listPendingNotices() {
        return ApiResponse.success(retentionApplicationService.listPendingNotices(
                CurrentUserContext.getRequired().userId()));
    }

    @PostMapping("/milestone-notices/{noticeId}/dismiss")
    public ApiResponse<Void> dismissNotice(@PathVariable UUID noticeId) {
        retentionApplicationService.dismissNotice(CurrentUserContext.getRequired().userId(), noticeId);
        return ApiResponse.success();
    }
}
