package com.leanmate.retention.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.leanmate.diet.domain.FoodEntryStatus;
import com.leanmate.diet.repository.FoodEntryRepository;
import com.leanmate.retention.dto.RetentionNoticeResponse;
import com.leanmate.retention.dto.StreakResponse;
import com.leanmate.retention.repository.AchievementEntity;
import com.leanmate.retention.repository.AchievementRepository;
import com.leanmate.retention.repository.RetentionNoticeEntity;
import com.leanmate.retention.repository.RetentionNoticeRepository;
import com.leanmate.stats.repository.StreakEntity;
import com.leanmate.stats.repository.StreakRepository;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.repository.UserEntity;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.weight.repository.WeightEntryRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

class RetentionApplicationServiceTests {

    private static final UUID USER_ID = UUID.fromString("77777777-7777-7777-7777-777777777777");
    private static final LocalDate TODAY = LocalDate.parse("2026-06-07");
    private static final Instant NOW = Instant.parse("2026-06-06T16:00:00Z");

    private CurrentUserApplicationService currentUserApplicationService;
    private UserProfileRepository userProfileRepository;
    private FoodEntryRepository foodEntryRepository;
    private WeightEntryRepository weightEntryRepository;
    private StreakRepository streakRepository;
    private AchievementRepository achievementRepository;
    private RetentionNoticeRepository retentionNoticeRepository;
    private RetentionApplicationService retentionApplicationService;

    @BeforeEach
    void setUp() {
        currentUserApplicationService = mock(CurrentUserApplicationService.class);
        userProfileRepository = mock(UserProfileRepository.class);
        foodEntryRepository = mock(FoodEntryRepository.class);
        weightEntryRepository = mock(WeightEntryRepository.class);
        streakRepository = mock(StreakRepository.class);
        achievementRepository = mock(AchievementRepository.class);
        retentionNoticeRepository = mock(RetentionNoticeRepository.class);
        retentionApplicationService = new RetentionApplicationService(
                currentUserApplicationService,
                userProfileRepository,
                foodEntryRepository,
                weightEntryRepository,
                streakRepository,
                achievementRepository,
                retentionNoticeRepository,
                Clock.fixed(NOW, ZoneOffset.UTC));

        when(currentUserApplicationService.requireActiveUser(USER_ID)).thenReturn(new UserEntity());
        when(userProfileRepository.findByUserId(USER_ID)).thenReturn(Optional.of(profile()));
        when(foodEntryRepository.findDistinctMealDatesOnOrBefore(
                USER_ID,
                FoodEntryStatus.CONFIRMED.value(),
                TODAY))
                .thenReturn(List.of());
        when(weightEntryRepository.findDistinctRecordDatesOnOrBefore(USER_ID, TODAY)).thenReturn(List.of());
        when(streakRepository.findByUserId(USER_ID)).thenReturn(Optional.empty());
        when(streakRepository.save(any(StreakEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(achievementRepository.findByUserIdAndTypeIn(eq(USER_ID), any())).thenReturn(List.of());
        when(achievementRepository.saveAll(any())).thenAnswer(invocation -> {
            Iterable<AchievementEntity> achievements = invocation.getArgument(0);
            List<AchievementEntity> saved = new ArrayList<>();
            achievements.forEach(saved::add);
            return saved;
        });
        when(retentionNoticeRepository.findByUserIdAndTypeAndMilestoneValue(eq(USER_ID), eq("streak"), any()))
                .thenReturn(Optional.empty());
        when(retentionNoticeRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void returnZeroStreakWhenNoActiveDays() {
        StreakResponse response = retentionApplicationService.getStreak(USER_ID);

        assertThat(response.currentDays()).isZero();
        assertThat(response.longestDays()).isZero();
        assertThat(response.lastActiveDate()).isNull();
        assertThat(response.milestones())
                .extracting("days", "achieved", "achievedAt")
                .containsExactly(
                        org.assertj.core.groups.Tuple.tuple(3, false, null),
                        org.assertj.core.groups.Tuple.tuple(7, false, null),
                        org.assertj.core.groups.Tuple.tuple(12, false, null),
                        org.assertj.core.groups.Tuple.tuple(30, false, null),
                        org.assertj.core.groups.Tuple.tuple(100, false, null));

        ArgumentCaptor<StreakEntity> streakCaptor = ArgumentCaptor.forClass(StreakEntity.class);
        verify(streakRepository).save(streakCaptor.capture());
        assertThat(streakCaptor.getValue().getCurrentDays()).isZero();
        assertThat(streakCaptor.getValue().getLongestDays()).isZero();
        assertThat(streakCaptor.getValue().getLastActiveDate()).isNull();
        verify(achievementRepository, never()).saveAll(any());
    }

    @Test
    void calculateCurrentAndLongestFromFoodAndWeightActiveDates() {
        when(foodEntryRepository.findDistinctMealDatesOnOrBefore(
                USER_ID,
                FoodEntryStatus.CONFIRMED.value(),
                TODAY))
                .thenReturn(List.of(
                        LocalDate.parse("2026-06-03"),
                        LocalDate.parse("2026-06-04"),
                        LocalDate.parse("2026-06-07")));
        when(weightEntryRepository.findDistinctRecordDatesOnOrBefore(USER_ID, TODAY))
                .thenReturn(List.of(
                        LocalDate.parse("2026-06-05"),
                        LocalDate.parse("2026-06-06")));

        StreakResponse response = retentionApplicationService.getStreak(USER_ID);

        assertThat(response.currentDays()).isEqualTo(5);
        assertThat(response.longestDays()).isEqualTo(5);
        assertThat(response.lastActiveDate()).isEqualTo(TODAY);
        assertThat(response.milestones().get(0).achieved()).isTrue();
        assertThat(response.milestones().get(0).achievedAt()).isEqualTo(NOW);
        assertThat(response.milestones().get(1).achieved()).isFalse();

        ArgumentCaptor<StreakEntity> streakCaptor = ArgumentCaptor.forClass(StreakEntity.class);
        verify(streakRepository).save(streakCaptor.capture());
        assertThat(streakCaptor.getValue().getCurrentDays()).isEqualTo(5);
        assertThat(streakCaptor.getValue().getLongestDays()).isEqualTo(5);

        verify(achievementRepository).saveAll(argThat(achievements -> {
            List<AchievementEntity> saved = new ArrayList<>();
            achievements.forEach(saved::add);
            return saved.size() == 1 && "streak_3".equals(saved.get(0).getType());
        }));
    }

    @Test
    void keepCurrentStreakWhenLastActiveDateIsYesterday() {
        when(foodEntryRepository.findDistinctMealDatesOnOrBefore(
                USER_ID,
                FoodEntryStatus.CONFIRMED.value(),
                TODAY))
                .thenReturn(List.of(LocalDate.parse("2026-06-05")));
        when(weightEntryRepository.findDistinctRecordDatesOnOrBefore(USER_ID, TODAY))
                .thenReturn(List.of(LocalDate.parse("2026-06-06")));

        StreakResponse response = retentionApplicationService.getStreak(USER_ID);

        assertThat(response.currentDays()).isEqualTo(2);
        assertThat(response.longestDays()).isEqualTo(2);
        assertThat(response.lastActiveDate()).isEqualTo(LocalDate.parse("2026-06-06"));
    }

    @Test
    void resetCurrentStreakAfterOneDayGap() {
        when(foodEntryRepository.findDistinctMealDatesOnOrBefore(
                USER_ID,
                FoodEntryStatus.CONFIRMED.value(),
                TODAY))
                .thenReturn(List.of(
                        LocalDate.parse("2026-06-01"),
                        LocalDate.parse("2026-06-02")));

        StreakResponse response = retentionApplicationService.getStreak(USER_ID);

        assertThat(response.currentDays()).isZero();
        assertThat(response.longestDays()).isEqualTo(2);
        assertThat(response.lastActiveDate()).isEqualTo(LocalDate.parse("2026-06-02"));
    }

    @Test
    void returnExistingMilestoneAchievement() {
        AchievementEntity existingAchievement = new AchievementEntity();
        existingAchievement.setUserId(USER_ID);
        existingAchievement.setType("streak_7");
        existingAchievement.setAchievedAt(Instant.parse("2026-05-01T00:00:00Z"));
        when(achievementRepository.findByUserIdAndTypeIn(eq(USER_ID), any()))
                .thenReturn(List.of(existingAchievement));
        when(foodEntryRepository.findDistinctMealDatesOnOrBefore(
                USER_ID,
                FoodEntryStatus.CONFIRMED.value(),
                TODAY))
                .thenReturn(List.of(TODAY));

        StreakResponse response = retentionApplicationService.getStreak(USER_ID);

        assertThat(response.longestDays()).isEqualTo(1);
        assertThat(response.milestones().get(1).achieved()).isTrue();
        assertThat(response.milestones().get(1).achievedAt())
                .isEqualTo(Instant.parse("2026-05-01T00:00:00Z"));
        verify(achievementRepository, never()).saveAll(any());
    }

    @Test
    void listPendingNoticesRefreshesStreakBeforeQuery() {
        when(foodEntryRepository.findDistinctMealDatesOnOrBefore(
                USER_ID,
                FoodEntryStatus.CONFIRMED.value(),
                TODAY))
                .thenReturn(List.of(
                        LocalDate.parse("2026-06-05"),
                        LocalDate.parse("2026-06-06"),
                        LocalDate.parse("2026-06-07")));

        RetentionNoticeEntity pendingNotice = new RetentionNoticeEntity();
        pendingNotice.setUserId(USER_ID);
        pendingNotice.setType("streak");
        pendingNotice.setMilestoneValue(3);
        pendingNotice.setTitle("连续记录 3 天");
        pendingNotice.setMessage("今天也完成记录，继续保持现在的节奏。");
        pendingNotice.setTriggeredAt(NOW);
        when(retentionNoticeRepository.findByUserIdAndStatusOrderByTriggeredAtAsc(USER_ID, "pending"))
                .thenReturn(List.of(pendingNotice));

        List<RetentionNoticeResponse> responses = retentionApplicationService.listPendingNotices(USER_ID);

        assertThat(responses).hasSize(1);
        assertThat(responses.get(0).currentValue()).isEqualTo(3);
        assertThat(responses.get(0).previousValue()).isNull();
        assertThat(responses.get(0).nextValue()).isEqualTo(7);
        verify(retentionNoticeRepository).save(any(RetentionNoticeEntity.class));
    }

    private UserProfileEntity profile() {
        UserProfileEntity profile = new UserProfileEntity();
        profile.setUserId(USER_ID);
        profile.setTimezone("Asia/Shanghai");
        return profile;
    }

}
