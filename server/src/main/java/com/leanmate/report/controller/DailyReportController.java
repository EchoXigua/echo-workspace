package com.leanmate.report.controller;

import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.report.application.DailyReportApplicationService;
import com.leanmate.report.dto.DailyReportResponse;
import com.leanmate.report.dto.GenerateDailyReportRequest;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/reports/daily")
public class DailyReportController {

    private final DailyReportApplicationService dailyReportApplicationService;

    public DailyReportController(DailyReportApplicationService dailyReportApplicationService) {
        this.dailyReportApplicationService = dailyReportApplicationService;
    }

    @GetMapping
    public ApiResponse<DailyReportResponse> getDailyReport(@RequestParam LocalDate date) {
        return ApiResponse.success(dailyReportApplicationService.getDailyReport(
                CurrentUserContext.getRequired().userId(),
                date));
    }

    @PostMapping
    public ApiResponse<DailyReportResponse> generateDailyReport(
            @Valid @RequestBody(required = false) GenerateDailyReportRequest request
    ) {
        return ApiResponse.success(dailyReportApplicationService.generateDailyReport(
                CurrentUserContext.getRequired().userId(),
                request));
    }

    @PostMapping("/{reportId}/view")
    public ApiResponse<DailyReportResponse> markViewed(@PathVariable UUID reportId) {
        return ApiResponse.success(dailyReportApplicationService.markViewed(
                CurrentUserContext.getRequired().userId(),
                reportId));
    }
}
