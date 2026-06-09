package com.leanmate.user.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.leanmate.user.domain.ActivityLevel;
import com.leanmate.user.domain.Gender;
import com.leanmate.user.domain.ProfileCalculator;
import com.leanmate.user.dto.CalorieTargetSuggestionResponse;
import com.leanmate.user.repository.UserEntity;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.user.repository.WeightGoalRepository;
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

class UserProfileApplicationServiceTests {

    private static final UUID USER_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private CurrentUserApplicationService currentUserApplicationService;
    private UserProfileRepository userProfileRepository;
    private WeightEntryRepository weightEntryRepository;
    private UserProfileApplicationService userProfileApplicationService;

    @BeforeEach
    void setUp() {
        currentUserApplicationService = mock(CurrentUserApplicationService.class);
        userProfileRepository = mock(UserProfileRepository.class);
        WeightGoalRepository weightGoalRepository = mock(WeightGoalRepository.class);
        weightEntryRepository = mock(WeightEntryRepository.class);
        userProfileApplicationService = new UserProfileApplicationService(
                currentUserApplicationService,
                userProfileRepository,
                weightGoalRepository,
                weightEntryRepository,
                new ProfileCalculator(),
                Clock.fixed(Instant.parse("2026-06-07T00:00:00Z"), ZoneOffset.UTC));

        when(currentUserApplicationService.requireActiveUser(USER_ID)).thenReturn(new UserEntity());
        when(userProfileRepository.findByUserId(USER_ID)).thenReturn(Optional.of(profile()));
    }

    @Test
    void calorieTargetSuggestionReturnsInsufficientDataWhenWeightTrendIsMissing() {
        LocalDate today = LocalDate.parse("2026-06-07");
        when(weightEntryRepository.findByUserIdAndRecordDateBetweenOrderByRecordDateAsc(
                USER_ID,
                today.minusDays(13),
                today))
                .thenReturn(List.of(weight(today.minusDays(1), "79.90")));

        CalorieTargetSuggestionResponse response = userProfileApplicationService
                .getCalorieTargetSuggestion(USER_ID);

        assertThat(response.status()).isEqualTo("insufficient_data");
        assertThat(response.currentTargetKcal()).isEqualTo(1800);
        assertThat(response.suggestedTargetKcal()).isEqualTo(1800);
        assertThat(response.requiresUserConfirmation()).isFalse();
    }

    @Test
    void calorieTargetSuggestionSuggestsLowerTargetWhenWeightLossIsSlowerThanExpected() {
        LocalDate today = LocalDate.parse("2026-06-07");
        when(weightEntryRepository.findByUserIdAndRecordDateBetweenOrderByRecordDateAsc(
                USER_ID,
                today.minusDays(13),
                today))
                .thenReturn(List.of(
                        weight(today.minusDays(13), "80.00"),
                        weight(today.minusDays(12), "80.10"),
                        weight(today.minusDays(11), "79.90"),
                        weight(today.minusDays(2), "79.95"),
                        weight(today.minusDays(1), "79.90"),
                        weight(today, "79.85")));

        CalorieTargetSuggestionResponse response = userProfileApplicationService
                .getCalorieTargetSuggestion(USER_ID);

        assertThat(response.status()).isEqualTo("suggest_lower");
        assertThat(response.currentTargetKcal()).isEqualTo(1800);
        assertThat(response.suggestedTargetKcal()).isEqualTo(1700);
        assertThat(response.changeKcal()).isEqualTo(-100);
        assertThat(response.requiresUserConfirmation()).isTrue();
        assertThat(response.startAverageWeightKg()).isEqualByComparingTo("80.00");
        assertThat(response.endAverageWeightKg()).isEqualByComparingTo("79.90");
        assertThat(response.weeklyWeightChangeKg()).isEqualByComparingTo("-0.10");
    }

    private UserProfileEntity profile() {
        UserProfileEntity profile = new UserProfileEntity();
        profile.setUserId(USER_ID);
        profile.setGender(Gender.MALE.value());
        profile.setAge(30);
        profile.setHeightCm(new BigDecimal("175.00"));
        profile.setCurrentWeightKg(new BigDecimal("80.00"));
        profile.setTargetWeightKg(new BigDecimal("72.00"));
        profile.setActivityLevel(ActivityLevel.LIGHT.value());
        profile.setTimezone("Asia/Shanghai");
        profile.setBmi(new BigDecimal("26.12"));
        profile.setBmrKcal(1740);
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
