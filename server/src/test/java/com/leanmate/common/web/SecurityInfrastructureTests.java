package com.leanmate.common.web;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.leanmate.LeanMateApplication;
import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.common.security.JwtTokenService;
import com.leanmate.diet.repository.FoodEntryRepository;
import com.leanmate.diet.repository.FoodItemRepository;
import com.leanmate.stats.repository.DailyAiReportSummaryRepository;
import com.leanmate.stats.repository.DailyNutritionSnapshotRepository;
import com.leanmate.stats.repository.FoodEntrySummaryRepository;
import com.leanmate.stats.repository.FoodNutritionSummaryRepository;
import com.leanmate.stats.repository.StreakRepository;
import com.leanmate.user.repository.RefreshTokenRepository;
import com.leanmate.user.repository.UserAuthIdentityRepository;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.user.repository.UserRepository;
import com.leanmate.user.repository.WeightGoalRepository;
import com.leanmate.weight.repository.WeightEntryRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@SpringBootTest(
        classes = {
                LeanMateApplication.class,
                SecurityInfrastructureTests.TestControllerConfiguration.class
        },
        properties = {
                "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,"
                        + "org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration,"
                        + "org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration,"
                        + "org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration",
                "leanmate.jwt.issuer=leanmate-test",
                "leanmate.jwt.secret=leanmate-test-jwt-secret-with-enough-length",
                "leanmate.jwt.access-token-ttl-seconds=3600",
                "leanmate.jwt.refresh-token-ttl-days=30"
        })
@AutoConfigureMockMvc
class SecurityInfrastructureTests {

    private final MockMvc mockMvc;
    private final JwtTokenService jwtTokenService;

    @MockitoBean
    UserRepository userRepository;

    @MockitoBean
    UserAuthIdentityRepository userAuthIdentityRepository;

    @MockitoBean
    RefreshTokenRepository refreshTokenRepository;

    @MockitoBean
    UserProfileRepository userProfileRepository;

    @MockitoBean
    WeightGoalRepository weightGoalRepository;

    @MockitoBean
    WeightEntryRepository weightEntryRepository;

    @MockitoBean
    DailyNutritionSnapshotRepository dailyNutritionSnapshotRepository;

    @MockitoBean
    FoodEntrySummaryRepository foodEntrySummaryRepository;

    @MockitoBean
    DailyAiReportSummaryRepository dailyAiReportSummaryRepository;

    @MockitoBean
    StreakRepository streakRepository;

    @MockitoBean
    FoodNutritionSummaryRepository foodNutritionSummaryRepository;

    @MockitoBean
    FoodEntryRepository foodEntryRepository;

    @MockitoBean
    FoodItemRepository foodItemRepository;

    @Autowired
    SecurityInfrastructureTests(MockMvc mockMvc, JwtTokenService jwtTokenService) {
        this.mockMvc = mockMvc;
        this.jwtTokenService = jwtTokenService;
    }

    @Test
    void rejectUnauthenticatedRequest() throws Exception {
        mockMvc.perform(get("/test/secure"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(40101))
                .andExpect(jsonPath("$.message").value("未登录或登录已过期"));
    }

    @Test
    void rejectInvalidTokenRequest() throws Exception {
        mockMvc.perform(get("/test/secure")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer invalid-token"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(40101))
                .andExpect(jsonPath("$.message").value("未登录或登录已过期"));
    }

    @Test
    void allowAuthenticatedRequestAndExposeCurrentUser() throws Exception {
        UUID userId = UUID.fromString("44444444-4444-4444-4444-444444444444");
        String token = jwtTokenService.generateAccessToken(userId);

        mockMvc.perform(get("/test/secure")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data").value(userId.toString()));
    }

    @Test
    void returnValidationErrorResponse() throws Exception {
        UUID userId = UUID.fromString("55555555-5555-5555-5555-555555555555");
        String token = jwtTokenService.generateAccessToken(userId);

        mockMvc.perform(post("/test/validation")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(40001))
                .andExpect(jsonPath("$.message").value("name: 不能为空"));
    }

    @Test
    void keepBusinessExceptionHandledByGlobalHandlerAfterAuthentication() throws Exception {
        UUID userId = UUID.fromString("66666666-6666-6666-6666-666666666666");
        String token = jwtTokenService.generateAccessToken(userId);

        mockMvc.perform(get("/test/business-error")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(40001))
                .andExpect(jsonPath("$.message").value("业务错误"));
    }

    @TestConfiguration
    static class TestControllerConfiguration {

        @Bean
        TestController testController() {
            return new TestController();
        }
    }

    @RestController
    static class TestController {

        @GetMapping("/test/secure")
        ApiResponse<String> secure() {
            return ApiResponse.success(CurrentUserContext.getRequired().userId().toString());
        }

        @PostMapping("/test/validation")
        ApiResponse<Void> validation(@Valid @RequestBody ValidationRequest request) {
            return ApiResponse.success();
        }

        @GetMapping("/test/business-error")
        ApiResponse<Void> businessError() {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "业务错误");
        }
    }

    record ValidationRequest(@NotBlank(message = "不能为空") String name) {
    }
}
