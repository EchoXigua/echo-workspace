package com.leanmate.weight.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.stats.application.DailyNutritionSnapshotApplicationService;
import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.repository.UserEntity;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.weight.dto.SaveWeightEntryRequest;
import com.leanmate.weight.dto.WeightEntrySaveResultResponse;
import com.leanmate.weight.repository.WeightEntryEntity;
import com.leanmate.weight.repository.WeightEntryRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class WeightApplicationServiceTests {

    private static final UUID USER_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private CurrentUserApplicationService currentUserApplicationService;
    private UserProfileRepository userProfileRepository;
    private WeightEntryRepository weightEntryRepository;
    private DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService;
    private WeightApplicationService weightApplicationService;

    @BeforeEach
    void setUp() {
        currentUserApplicationService = mock(CurrentUserApplicationService.class);
        userProfileRepository = mock(UserProfileRepository.class);
        weightEntryRepository = mock(WeightEntryRepository.class);
        dailyNutritionSnapshotApplicationService = mock(DailyNutritionSnapshotApplicationService.class);
        weightApplicationService = new WeightApplicationService(
                currentUserApplicationService,
                userProfileRepository,
                weightEntryRepository,
                dailyNutritionSnapshotApplicationService,
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

    private UserProfileEntity profile() {
        UserProfileEntity profile = new UserProfileEntity();
        profile.setUserId(USER_ID);
        profile.setTimezone("Asia/Shanghai");
        profile.setDailyCalorieTargetKcal(1800);
        return profile;
    }
}
