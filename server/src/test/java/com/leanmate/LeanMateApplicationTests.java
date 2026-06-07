package com.leanmate;

import com.leanmate.diet.repository.AiRecognitionTaskRepository;
import com.leanmate.diet.repository.FoodEntryRepository;
import com.leanmate.diet.repository.FoodItemRepository;
import com.leanmate.report.repository.DailyAiReportRepository;
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
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

@SpringBootTest(properties = {
        "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,"
                + "org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration,"
                + "org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration,"
                + "org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration"
})
class LeanMateApplicationTests {

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
    DailyAiReportRepository dailyAiReportRepository;

    @MockitoBean
    StreakRepository streakRepository;

    @MockitoBean
    FoodNutritionSummaryRepository foodNutritionSummaryRepository;

    @MockitoBean
    FoodEntryRepository foodEntryRepository;

    @MockitoBean
    FoodItemRepository foodItemRepository;

    @MockitoBean
    AiRecognitionTaskRepository aiRecognitionTaskRepository;

    @Test
    void contextLoads() {
    }
}
