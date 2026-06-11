package com.leanmate.weight.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.retention.application.RetentionApplicationService;
import com.leanmate.stats.application.DailyNutritionSnapshotApplicationService;
import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.repository.UserEntity;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.user.repository.WeightGoalEntity;
import com.leanmate.user.repository.WeightGoalRepository;
import com.leanmate.weight.domain.WeightTrendDirection;
import com.leanmate.weight.dto.SaveWeightEntryRequest;
import com.leanmate.weight.dto.WeightEntrySaveResultResponse;
import com.leanmate.weight.dto.WeightTrendResponse;
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

class WeightApplicationServiceTests {

    private static final UUID USER_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private CurrentUserApplicationService currentUserApplicationService;
    private UserProfileRepository userProfileRepository;
    private WeightGoalRepository weightGoalRepository;
    private WeightEntryRepository weightEntryRepository;
    private DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService;
    private RetentionApplicationService retentionApplicationService;
    private WeightApplicationService weightApplicationService;

    @BeforeEach
    void setUp() {
        currentUserApplicationService = mock(CurrentUserApplicationService.class);
        userProfileRepository = mock(UserProfileRepository.class);
        weightGoalRepository = mock(WeightGoalRepository.class);
        weightEntryRepository = mock(WeightEntryRepository.class);
        dailyNutritionSnapshotApplicationService = mock(DailyNutritionSnapshotApplicationService.class);
        retentionApplicationService = mock(RetentionApplicationService.class);
        weightApplicationService = new WeightApplicationService(
                currentUserApplicationService,
                userProfileRepository,
                weightGoalRepository,
                weightEntryRepository,
                dailyNutritionSnapshotApplicationService,
                retentionApplicationService,
                Clock.fixed(Instant.parse("2026-06-07T00:00:00Z"), ZoneOffset.UTC));

        when(currentUserApplicationService.requireActiveUser(USER_ID)).thenReturn(new UserEntity());
    }

    @Test
    void overwriteSameDayWeightEntryAndRefreshSnapshot() {
        UserProfileEntity profile = profile();
        WeightEntryEntity existingEntry = new WeightEntryEntity();
        DailyNutritionSnapshotResponse snapshot = new DailyNutritionSnapshotResponse(
                LocalDate.parse("2026-06-07"),
                1800,
                0,
                1800,
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                0,
                new BigDecimal("78.35"));
        SaveWeightEntryRequest request = new SaveWeightEntryRequest(
                LocalDate.parse("2026-06-07"),
                new BigDecimal("78.345"),
                "  晨起空腹  ");

        when(userProfileRepository.findByUserId(USER_ID)).thenReturn(Optional.of(profile));
        when(weightEntryRepository.findByUserIdAndRecordDate(USER_ID, request.recordDate()))
                .thenReturn(Optional.of(existingEntry));
        when(weightEntryRepository.save(existingEntry)).thenReturn(existingEntry);
        when(dailyNutritionSnapshotApplicationService.updateWeight(
                USER_ID,
                request.recordDate(),
                1800,
                new BigDecimal("78.35")))
                .thenReturn(snapshot);

        WeightEntrySaveResultResponse response = weightApplicationService.saveWeight(USER_ID, request);

        assertThat(existingEntry.getWeightKg()).isEqualByComparingTo("78.35");
        assertThat(existingEntry.getNote()).isEqualTo("晨起空腹");
        assertThat(response.today().weightKg()).isEqualByComparingTo("78.35");
        verify(weightEntryRepository).save(existingEntry);
        verify(retentionApplicationService).getStreak(USER_ID);
    }

    @Test
    void rejectFutureRecordDateByUserTimezone() {
        SaveWeightEntryRequest request = new SaveWeightEntryRequest(
                LocalDate.parse("2026-06-08"),
                new BigDecimal("78.0"),
                null);

        when(userProfileRepository.findByUserId(USER_ID)).thenReturn(Optional.of(profile()));

        assertThatThrownBy(() -> weightApplicationService.saveWeight(USER_ID, request))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.BAD_REQUEST);
        verifyNoInteractions(dailyNutritionSnapshotApplicationService);
        verifyNoInteractions(retentionApplicationService);
    }

    @Test
    void rejectTooLargeQueryRange() {
        assertThatThrownBy(() -> weightApplicationService.listWeights(
                USER_ID,
                LocalDate.parse("2026-01-01"),
                LocalDate.parse("2026-07-01")))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.BAD_REQUEST);
    }

    @Test
    void returnWeightTrendWithTargetAndPoints() {
        LocalDate today = LocalDate.parse("2026-06-07");
        WeightGoalEntity goal = new WeightGoalEntity();
        goal.setTargetWeightKg(new BigDecimal("72.00"));
        WeightEntryEntity first = weight(today.minusDays(3), "80.00");
        WeightEntryEntity latest = weight(today, "79.40");

        when(userProfileRepository.findByUserId(USER_ID)).thenReturn(Optional.of(profile()));
        when(weightGoalRepository.findFirstByUserIdAndStatusOrderByCreatedAtDesc(USER_ID, "active"))
                .thenReturn(Optional.of(goal));
        when(weightEntryRepository.findByUserIdAndRecordDateBetweenOrderByRecordDateAsc(
                USER_ID,
                today.minusDays(29),
                today))
                .thenReturn(List.of(first, latest));

        WeightTrendResponse response = weightApplicationService.getTrend(USER_ID, 30);

        assertThat(response.targetWeightKg()).isEqualByComparingTo("72.00");
        assertThat(response.startWeightKg()).isEqualByComparingTo("80.00");
        assertThat(response.latestWeightKg()).isEqualByComparingTo("79.40");
        assertThat(response.changeKg()).isEqualByComparingTo("-0.60");
        assertThat(response.direction()).isEqualTo(WeightTrendDirection.DECREASING);
        assertThat(response.points()).hasSize(2);
        assertThat(response.points().get(1).isToday()).isTrue();
    }

    private UserProfileEntity profile() {
        UserProfileEntity profile = new UserProfileEntity();
        profile.setUserId(USER_ID);
        profile.setTimezone("Asia/Shanghai");
        profile.setDailyCalorieTargetKcal(1800);
        return profile;
    }

    private WeightEntryEntity weight(LocalDate date, String weightKg) {
        WeightEntryEntity entry = new WeightEntryEntity();
        entry.setUserId(USER_ID);
        entry.setRecordDate(date);
        entry.setWeightKg(new BigDecimal(weightKg));
        return entry;
    }
}
