package com.leanmate.stats.controller;

import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.stats.application.HomeApplicationService;
import com.leanmate.stats.dto.TodayHomeResponse;
import java.time.LocalDate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/home")
public class HomeController {

    private final HomeApplicationService homeApplicationService;

    public HomeController(HomeApplicationService homeApplicationService) {
        this.homeApplicationService = homeApplicationService;
    }

    @GetMapping("/today")
    public ApiResponse<TodayHomeResponse> getToday(@RequestParam(required = false) LocalDate date) {
        return ApiResponse.success(homeApplicationService.getToday(
                CurrentUserContext.getRequired().userId(),
                date));
    }
}
