package com.leanmate.stats.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.stats.dto.TodayHomeResponse;
import com.leanmate.stats.repository.DailyAiReportSummaryRepository;
import com.leanmate.stats.repository.FoodEntrySummaryRepository;
import com.leanmate.stats.repository.FoodEntrySummaryRow;
import com.leanmate.stats.repository.StreakEntity;
import com.leanmate.stats.repository.StreakRepository;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.repository.UserEntity;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.weight.repository.WeightEntryEntity;
import com.leanmate.weight.repository.WeightEntryRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class HomeApplicationServiceTests {

    private static final UUID USER_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    private CurrentUserApplicationService currentUserApplicationService;
    private UserProfileRepository userProfileRepository;
    private WeightEntryRepository weightEntryRepository;
    private DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService;
    private FoodEntrySummaryRepository foodEntrySummaryRepository;
    private DailyAiReportSummaryRepository dailyAiReportSummaryRepository;
    private StreakRepository streakRepository;
    private HomeApplicationService homeApplicationService;

    @BeforeEach
    void setUp() {
        currentUserApplicationService = mock(CurrentUserApplicationService.class);
        userProfileRepository = mock(UserProfileRepository.class);
        weightEntryRepository = mock(WeightEntryRepository.class);
        dailyNutritionSnapshotApplicationService = mock(DailyNutritionSnapshotApplicationService.class);
        foodEntrySummaryRepository = mock(FoodEntrySummaryRepository.class);
        dailyAiReportSummaryRepository = mock(DailyAiReportSummaryRepository.class);
        streakRepository = mock(StreakRepository.class);
        homeApplicationService = new HomeApplicationService(
                currentUserApplicationService,
                userProfileRepository,
                weightEntryRepository,
                dailyNutritionSnapshotApplicationService,
                foodEntrySummaryRepository,
                dailyAiReportSummaryRepository,
                streakRepository,
                Clock.fixed(Instant.parse("2026-06-07T00:00:00Z"), ZoneOffset.UTC));

        when(currentUserApplicationService.requireActiveUser(USER_ID)).thenReturn(new UserEntity());
    }

    @Test
    void returnGuideStateWhenProfileIncomplete() {
        when(userProfileRepository.findByUserId(USER_ID)).thenReturn(Optional.empty());

        TodayHomeResponse response = homeApplicationService.getToday(USER_ID, null);

        assertThat(response.profileCompleted()).isFalse();
        assertThat(response.date()).isEqualTo(LocalDate.parse("2026-06-07"));
        assertThat(response.calorieTargetKcal()).isZero();
        assertThat(response.foodEntries()).isEmpty();
        verifyNoInteractions(dailyNutritionSnapshotApplicationService, foodEntrySummaryRepository);
    }

    @Test
    void returnCompletedProfileHomeWithLatestWeightAndSummaries() {
        UserProfileEntity profile = profile();
        DailyNutritionSnapshotResponse snapshot = new DailyNutritionSnapshotResponse(
                LocalDate.parse("2026-06-07"),
                1800,
                520,
                1280,
                new BigDecimal("35.20"),
                new BigDecimal("18.00"),
                new BigDecimal("62.50"),
                1,
                null);
        WeightEntryEntity latestWeight = new WeightEntryEntity();
        latestWeight.setWeightKg(new BigDecimal("78.50"));
        StreakEntity streak = new StreakEntity();
        streak.setCurrentDays(7);
        FoodEntrySummaryRow foodRow = mock(FoodEntrySummaryRow.class);

        when(userProfileRepository.findByUserId(USER_ID)).thenReturn(Optional.of(profile));
        when(dailyNutritionSnapshotApplicationService.getOrCreateForHome(
                USER_ID,
                LocalDate.parse("2026-06-07"),
                1800))
                .thenReturn(snapshot);
        when(weightEntryRepository.findFirstByUserIdAndRecordDateLessThanEqualOrderByRecordDateDesc(
                USER_ID,
                LocalDate.parse("2026-06-07")))
                .thenReturn(Optional.of(latestWeight));
        when(foodEntrySummaryRepository.findConfirmedSummaries(USER_ID, LocalDate.parse("2026-06-07")))
                .thenReturn(List.of(foodRow));
        when(foodRow.getId()).thenReturn(UUID.fromString("33333333-3333-3333-3333-333333333333"));
        when(foodRow.getMealType()).thenReturn("lunch");
        when(foodRow.getTotalCaloriesKcal()).thenReturn(520);
        when(foodRow.getItemNamesText()).thenReturn("鸡胸肉\u001F米饭");
        when(streakRepository.findByUserId(USER_ID)).thenReturn(Optional.of(streak));
        when(dailyAiReportSummaryRepository.findGeneratedSummary(USER_ID, LocalDate.parse("2026-06-07")))
                .thenReturn(Optional.of("今天摄入稳定。"));

        TodayHomeResponse response = homeApplicationService.getToday(USER_ID, null);

        assertThat(response.profileCompleted()).isTrue();
        assertThat(response.currentWeightKg()).isEqualByComparingTo("78.50");
        assertThat(response.streakDays()).isEqualTo(7);
        assertThat(response.reportSummary()).isEqualTo("今天摄入稳定。");
        assertThat(response.foodEntries()).hasSize(1);
        assertThat(response.foodEntries().get(0).itemNames()).containsExactly("鸡胸肉", "米饭");
    }

    private UserProfileEntity profile() {
        UserProfileEntity profile = new UserProfileEntity();
        profile.setUserId(USER_ID);
        profile.setTimezone("Asia/Shanghai");
        profile.setCurrentWeightKg(new BigDecimal("80.00"));
        profile.setDailyCalorieTargetKcal(1800);
        return profile;
    }
}
