package com.leanmate.report.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.leanmate.ai.client.AiProviderException;
import com.leanmate.ai.client.DailyReportClient;
import com.leanmate.ai.dto.DailyReportInput;
import com.leanmate.ai.dto.DailyReportResult;
import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.diet.domain.FoodEntrySourceType;
import com.leanmate.diet.domain.FoodEntryStatus;
import com.leanmate.diet.domain.MealType;
import com.leanmate.diet.repository.FoodEntryEntity;
import com.leanmate.diet.repository.FoodEntryRepository;
import com.leanmate.diet.repository.FoodItemEntity;
import com.leanmate.diet.repository.FoodItemRepository;
import com.leanmate.report.domain.DailyReportStatus;
import com.leanmate.report.dto.DailyReportResponse;
import com.leanmate.report.dto.GenerateDailyReportRequest;
import com.leanmate.report.repository.DailyAiReportEntity;
import com.leanmate.report.repository.DailyAiReportRepository;
import com.leanmate.stats.application.DailyNutritionSnapshotApplicationService;
import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.stats.repository.DailyNutritionSnapshotEntity;
import com.leanmate.stats.repository.DailyNutritionSnapshotRepository;
import com.leanmate.stats.repository.StreakEntity;
import com.leanmate.stats.repository.StreakRepository;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.domain.WeightGoalStatus;
import com.leanmate.user.repository.UserEntity;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.user.repository.WeightGoalEntity;
import com.leanmate.user.repository.WeightGoalRepository;
import com.leanmate.weight.repository.WeightEntryEntity;
import com.leanmate.weight.repository.WeightEntryRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DailyReportApplicationServiceTests {

    private static final UUID USER_ID = UUID.fromString("11111111-2222-3333-4444-555555555555");
    private static final UUID OTHER_USER_ID = UUID.fromString("99999999-2222-3333-4444-555555555555");
    private static final UUID REPORT_ID = UUID.fromString("aaaaaaaa-1111-2222-3333-444444444444");
    private static final UUID FOOD_ENTRY_ID = UUID.fromString("bbbbbbbb-1111-2222-3333-444444444444");
    private static final LocalDate REPORT_DATE = LocalDate.parse("2026-06-07");

    private CurrentUserApplicationService currentUserApplicationService;
    private UserProfileRepository userProfileRepository;
    private WeightGoalRepository weightGoalRepository;
    private WeightEntryRepository weightEntryRepository;
    private FoodEntryRepository foodEntryRepository;
    private FoodItemRepository foodItemRepository;
    private DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService;
    private DailyNutritionSnapshotRepository dailyNutritionSnapshotRepository;
    private StreakRepository streakRepository;
    private DailyAiReportRepository dailyAiReportRepository;
    private DailyReportClient dailyReportClient;
    private DailyReportApplicationService dailyReportApplicationService;

    @BeforeEach
    void setUp() {
        currentUserApplicationService = mock(CurrentUserApplicationService.class);
        userProfileRepository = mock(UserProfileRepository.class);
        weightGoalRepository = mock(WeightGoalRepository.class);
        weightEntryRepository = mock(WeightEntryRepository.class);
        foodEntryRepository = mock(FoodEntryRepository.class);
        foodItemRepository = mock(FoodItemRepository.class);
        dailyNutritionSnapshotApplicationService = mock(DailyNutritionSnapshotApplicationService.class);
        dailyNutritionSnapshotRepository = mock(DailyNutritionSnapshotRepository.class);
        streakRepository = mock(StreakRepository.class);
        dailyAiReportRepository = mock(DailyAiReportRepository.class);
        dailyReportClient = mock(DailyReportClient.class);
        dailyReportApplicationService = new DailyReportApplicationService(
                currentUserApplicationService,
                userProfileRepository,
                weightGoalRepository,
                weightEntryRepository,
                foodEntryRepository,
                foodItemRepository,
                dailyNutritionSnapshotApplicationService,
                dailyNutritionSnapshotRepository,
                streakRepository,
                dailyAiReportRepository,
                dailyReportClient,
                Clock.fixed(Instant.parse("2026-06-07T00:00:00Z"), ZoneOffset.UTC));

        when(currentUserApplicationService.requireActiveUser(USER_ID)).thenReturn(new UserEntity());
        when(userProfileRepository.findByUserId(USER_ID)).thenReturn(Optional.of(profile()));
    }

    @Test
    void getDailyReportReturnsNullWhenMissing() {
        when(dailyAiReportRepository.findByUserIdAndReportDate(USER_ID, REPORT_DATE))
                .thenReturn(Optional.empty());

        DailyReportResponse response = dailyReportApplicationService.getDailyReport(USER_ID, REPORT_DATE);

        assertThat(response).isNull();
    }

    @Test
    void generateReportFromStructuredInputsAndOverwriteSameDayReport() {
        FoodEntryEntity foodEntry = foodEntry();
        FoodItemEntity foodItem = foodItem();
        WeightEntryEntity weightEntry = weightEntry();
        DailyAiReportEntity existingReport = existingReport(USER_ID, DailyReportStatus.VIEWED);
        AtomicReference<DailyReportInput> capturedInput = new AtomicReference<>();

        when(foodEntryRepository.findByUserIdAndMealDateAndStatusOrderByCreatedAtAsc(
                USER_ID,
                REPORT_DATE,
                FoodEntryStatus.CONFIRMED.value()))
                .thenReturn(List.of(foodEntry));
        when(weightEntryRepository.findByUserIdAndRecordDate(USER_ID, REPORT_DATE))
                .thenReturn(Optional.of(weightEntry));
        when(dailyNutritionSnapshotApplicationService.recalculateDietTotals(USER_ID, REPORT_DATE, 1800))
                .thenReturn(snapshot(null));
        when(dailyNutritionSnapshotApplicationService.updateWeight(
                USER_ID,
                REPORT_DATE,
                1800,
                new BigDecimal("78.50")))
                .thenReturn(snapshot(new BigDecimal("78.50")));
        when(dailyNutritionSnapshotRepository.findByUserIdAndDate(USER_ID, REPORT_DATE))
                .thenReturn(Optional.of(snapshotEntity()));
        when(dailyAiReportRepository.findByUserIdAndReportDate(USER_ID, REPORT_DATE))
                .thenReturn(Optional.of(existingReport));
        when(foodItemRepository.findByFoodEntryIdOrderBySortOrderAsc(FOOD_ENTRY_ID))
                .thenReturn(List.of(foodItem));
        when(weightGoalRepository.findFirstByUserIdAndStatusOrderByCreatedAtDesc(
                USER_ID,
                WeightGoalStatus.ACTIVE.value()))
                .thenReturn(Optional.of(weightGoal()));
        when(streakRepository.findByUserId(USER_ID)).thenReturn(Optional.of(streak()));
        when(dailyReportClient.generateDailyReport(any(DailyReportInput.class), any(UUID.class))).thenAnswer(invocation -> {
            DailyReportInput input = invocation.getArgument(0);
            capturedInput.set(input);
            return new DailyReportResult(
                    "test-daily-report-model",
                    88,
                    " 今天整体控制不错。 ",
                    "晚餐热量略高。",
                    "明天晚餐减少油脂。",
                    Map.of("provider", "test"));
        });
        when(dailyAiReportRepository.save(any(DailyAiReportEntity.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        DailyReportResponse response = dailyReportApplicationService.generateDailyReport(
                USER_ID,
                new GenerateDailyReportRequest(REPORT_DATE));

        assertThat(response.id()).isEqualTo(REPORT_ID);
        assertThat(response.status()).isEqualTo(DailyReportStatus.GENERATED);
        assertThat(response.score()).isEqualTo(88);
        assertThat(response.summary()).isEqualTo("今天整体控制不错。");
        assertThat(response.generatedAt()).isEqualTo(Instant.parse("2026-06-07T00:00:00Z"));
        assertThat(response.viewedAt()).isNull();
        assertThat(capturedInput.get().foodEntries()).hasSize(1);
        assertThat(capturedInput.get().foodEntries().get(0).items()).hasSize(1);
        assertThat(capturedInput.get().weightEntry().weightKg()).isEqualByComparingTo("78.50");
        assertThat(capturedInput.get().snapshot().foodEntryCount()).isEqualTo(1);
        verify(foodItemRepository).findByFoodEntryIdOrderBySortOrderAsc(FOOD_ENTRY_ID);
    }

    @Test
    void rejectGenerateWhenNoFoodOrWeightRecord() {
        when(foodEntryRepository.findByUserIdAndMealDateAndStatusOrderByCreatedAtAsc(
                USER_ID,
                REPORT_DATE,
                FoodEntryStatus.CONFIRMED.value()))
                .thenReturn(List.of());
        when(weightEntryRepository.findByUserIdAndRecordDate(USER_ID, REPORT_DATE))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> dailyReportApplicationService.generateDailyReport(
                USER_ID,
                new GenerateDailyReportRequest(REPORT_DATE)))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.CONFLICT);
        verifyNoInteractions(dailyReportClient, dailyNutritionSnapshotApplicationService);
    }

    @Test
    void keepFailedReportWhenProviderFails() {
        FoodEntryEntity foodEntry = foodEntry();
        AtomicReference<DailyAiReportEntity> savedReport = new AtomicReference<>();

        when(foodEntryRepository.findByUserIdAndMealDateAndStatusOrderByCreatedAtAsc(
                USER_ID,
                REPORT_DATE,
                FoodEntryStatus.CONFIRMED.value()))
                .thenReturn(List.of(foodEntry));
        when(weightEntryRepository.findByUserIdAndRecordDate(USER_ID, REPORT_DATE))
                .thenReturn(Optional.empty());
        when(dailyNutritionSnapshotApplicationService.recalculateDietTotals(USER_ID, REPORT_DATE, 1800))
                .thenReturn(snapshot(null));
        when(dailyNutritionSnapshotRepository.findByUserIdAndDate(USER_ID, REPORT_DATE))
                .thenReturn(Optional.of(snapshotEntity()));
        when(dailyAiReportRepository.findByUserIdAndReportDate(USER_ID, REPORT_DATE))
                .thenReturn(Optional.empty());
        when(foodItemRepository.findByFoodEntryIdOrderBySortOrderAsc(FOOD_ENTRY_ID))
                .thenReturn(List.of(foodItem()));
        when(weightGoalRepository.findFirstByUserIdAndStatusOrderByCreatedAtDesc(
                USER_ID,
                WeightGoalStatus.ACTIVE.value()))
                .thenReturn(Optional.empty());
        when(streakRepository.findByUserId(USER_ID)).thenReturn(Optional.empty());
        when(dailyReportClient.generateDailyReport(any(DailyReportInput.class), any(UUID.class)))
                .thenThrow(new AiProviderException("provider_timeout", "AI 服务超时"));
        when(dailyAiReportRepository.save(any(DailyAiReportEntity.class))).thenAnswer(invocation -> {
            DailyAiReportEntity report = invocation.getArgument(0);
            report.setId(REPORT_ID);
            savedReport.set(report);
            return report;
        });

        DailyReportResponse response = dailyReportApplicationService.generateDailyReport(
                USER_ID,
                new GenerateDailyReportRequest(REPORT_DATE));

        assertThat(response.status()).isEqualTo(DailyReportStatus.FAILED);
        assertThat(response.score()).isNull();
        assertThat(response.summary()).isNull();
        assertThat(savedReport.get().getErrorCode()).isEqualTo("provider_timeout");
    }

    @Test
    void markGeneratedReportAsViewed() {
        DailyAiReportEntity report = existingReport(USER_ID, DailyReportStatus.GENERATED);
        when(dailyAiReportRepository.findById(REPORT_ID)).thenReturn(Optional.of(report));
        when(dailyAiReportRepository.save(report)).thenReturn(report);

        DailyReportResponse response = dailyReportApplicationService.markViewed(USER_ID, REPORT_ID);

        assertThat(response.status()).isEqualTo(DailyReportStatus.VIEWED);
        assertThat(response.viewedAt()).isEqualTo(Instant.parse("2026-06-07T00:00:00Z"));
    }

    @Test
    void rejectViewingOtherUserReport() {
        DailyAiReportEntity report = existingReport(OTHER_USER_ID, DailyReportStatus.GENERATED);
        when(dailyAiReportRepository.findById(REPORT_ID)).thenReturn(Optional.of(report));

        assertThatThrownBy(() -> dailyReportApplicationService.markViewed(USER_ID, REPORT_ID))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.FORBIDDEN);
    }

    private UserProfileEntity profile() {
        UserProfileEntity profile = new UserProfileEntity();
        profile.setUserId(USER_ID);
        profile.setGender("female");
        profile.setAge(30);
        profile.setHeightCm(new BigDecimal("165.00"));
        profile.setCurrentWeightKg(new BigDecimal("80.00"));
        profile.setTargetWeightKg(new BigDecimal("70.00"));
        profile.setActivityLevel("light");
        profile.setTimezone("Asia/Shanghai");
        profile.setDailyCalorieTargetKcal(1800);
        return profile;
    }

    private FoodEntryEntity foodEntry() {
        FoodEntryEntity entry = new FoodEntryEntity();
        entry.setId(FOOD_ENTRY_ID);
        entry.setUserId(USER_ID);
        entry.setMealDate(REPORT_DATE);
        entry.setMealType(MealType.LUNCH.value());
        entry.setSourceType(FoodEntrySourceType.MANUAL.value());
        entry.setStatus(FoodEntryStatus.CONFIRMED.value());
        entry.setTotalCaloriesKcal(520);
        entry.setTotalProteinG(new BigDecimal("35.20"));
        entry.setTotalFatG(new BigDecimal("18.00"));
        entry.setTotalCarbsG(new BigDecimal("62.50"));
        return entry;
    }

    private FoodItemEntity foodItem() {
        FoodItemEntity item = new FoodItemEntity();
        item.setFoodEntryId(FOOD_ENTRY_ID);
        item.setName("鸡胸肉");
        item.setQuantityText("150g");
        item.setWeightG(new BigDecimal("150.00"));
        item.setCaloriesKcal(250);
        item.setProteinG(new BigDecimal("31.50"));
        item.setFatG(new BigDecimal("5.00"));
        item.setCarbsG(new BigDecimal("0.00"));
        item.setUserEdited(true);
        item.setSortOrder(0);
        return item;
    }

    private WeightEntryEntity weightEntry() {
        WeightEntryEntity entry = new WeightEntryEntity();
        entry.setUserId(USER_ID);
        entry.setRecordDate(REPORT_DATE);
        entry.setWeightKg(new BigDecimal("78.50"));
        return entry;
    }

    private WeightGoalEntity weightGoal() {
        WeightGoalEntity goal = new WeightGoalEntity();
        goal.setUserId(USER_ID);
        goal.setStartWeightKg(new BigDecimal("80.00"));
        goal.setTargetWeightKg(new BigDecimal("70.00"));
        goal.setTargetDate(LocalDate.parse("2026-12-31"));
        goal.setDailyCalorieTargetKcal(1800);
        goal.setStatus(WeightGoalStatus.ACTIVE.value());
        return goal;
    }

    private StreakEntity streak() {
        StreakEntity streak = new StreakEntity();
        streak.setUserId(USER_ID);
        streak.setCurrentDays(3);
        streak.setLongestDays(7);
        streak.setLastActiveDate(REPORT_DATE);
        return streak;
    }

    private DailyNutritionSnapshotResponse snapshot(BigDecimal weightKg) {
        return new DailyNutritionSnapshotResponse(
                REPORT_DATE,
                1800,
                520,
                1280,
                new BigDecimal("35.20"),
                new BigDecimal("18.00"),
                new BigDecimal("62.50"),
                1,
                weightKg);
    }

    private DailyNutritionSnapshotEntity snapshotEntity() {
        DailyNutritionSnapshotEntity snapshot = new DailyNutritionSnapshotEntity();
        snapshot.setUserId(USER_ID);
        snapshot.setDate(REPORT_DATE);
        snapshot.setCalorieTargetKcal(1800);
        snapshot.setCaloriesKcal(520);
        snapshot.setRemainingCaloriesKcal(1280);
        snapshot.setFoodEntryCount(1);
        return snapshot;
    }

    private DailyAiReportEntity existingReport(UUID userId, DailyReportStatus status) {
        DailyAiReportEntity report = new DailyAiReportEntity();
        report.setId(REPORT_ID);
        report.setUserId(userId);
        report.setReportDate(REPORT_DATE);
        report.setStatus(status.value());
        report.setScore(70);
        report.setSummary("旧日报");
        report.setGeneratedAt(Instant.parse("2026-06-06T12:00:00Z"));
        report.setViewedAt(Instant.parse("2026-06-06T13:00:00Z"));
        return report;
    }
}
