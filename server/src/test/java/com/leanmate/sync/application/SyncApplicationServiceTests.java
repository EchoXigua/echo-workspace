package com.leanmate.sync.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.leanmate.diet.application.DietEntryApplicationService;
import com.leanmate.diet.dto.FoodEntryResponse;
import com.leanmate.diet.dto.LocalDietEntrySyncFailureResponse;
import com.leanmate.diet.dto.LocalDietEntrySyncItemRequest;
import com.leanmate.diet.dto.SyncLocalDietEntriesRequest;
import com.leanmate.diet.dto.SyncLocalDietEntriesResultResponse;
import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.sync.dto.LocalProfileSyncRequest;
import com.leanmate.sync.dto.SyncLocalRequest;
import com.leanmate.sync.dto.SyncLocalResultResponse;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.application.UserProfileApplicationService;
import com.leanmate.user.domain.ActivityLevel;
import com.leanmate.user.domain.Gender;
import com.leanmate.user.domain.GoalType;
import com.leanmate.user.dto.ProfilePayload;
import com.leanmate.user.dto.SaveUserProfileRequest;
import com.leanmate.user.dto.UserProfileResponse;
import com.leanmate.user.repository.UserEntity;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.weight.application.WeightApplicationService;
import com.leanmate.weight.dto.SyncLocalWeightEntryRequest;
import com.leanmate.weight.dto.WeightEntryResponse;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@SuppressWarnings("unchecked")
class SyncApplicationServiceTests {

    private static final UUID USER_ID = UUID.fromString("99999999-9999-9999-9999-999999999999");
    private static final UUID PROFILE_CLIENT_ID = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static final UUID WEIGHT_CLIENT_ID = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    private static final UUID DIET_CLIENT_ID = UUID.fromString("cccccccc-cccc-cccc-cccc-cccccccccccc");
    private static final Instant NOW = Instant.parse("2026-06-09T01:00:00Z");

    private CurrentUserApplicationService currentUserApplicationService;
    private UserProfileRepository userProfileRepository;
    private UserProfileApplicationService userProfileApplicationService;
    private DietEntryApplicationService dietEntryApplicationService;
    private WeightApplicationService weightApplicationService;
    private SyncApplicationService syncApplicationService;

    @BeforeEach
    void setUp() {
        currentUserApplicationService = mock(CurrentUserApplicationService.class);
        userProfileRepository = mock(UserProfileRepository.class);
        userProfileApplicationService = mock(UserProfileApplicationService.class);
        dietEntryApplicationService = mock(DietEntryApplicationService.class);
        weightApplicationService = mock(WeightApplicationService.class);
        syncApplicationService = new SyncApplicationService(
                currentUserApplicationService,
                userProfileRepository,
                userProfileApplicationService,
                dietEntryApplicationService,
                weightApplicationService);

        when(currentUserApplicationService.requireActiveUser(USER_ID)).thenReturn(new UserEntity());
    }

    @Test
    void syncLocalImportsProfileWeightAndDietEntries() {
        SaveUserProfileRequest profileRequest = profileRequest();
        LocalProfileSyncRequest profileSync = new LocalProfileSyncRequest(PROFILE_CLIENT_ID, NOW, profileRequest);
        SyncLocalWeightEntryRequest weightSync = new SyncLocalWeightEntryRequest(
                WEIGHT_CLIENT_ID,
                LocalDate.parse("2026-06-09"),
                new BigDecimal("75.00"),
                "早晨空腹",
                NOW,
                NOW);
        LocalDietEntrySyncItemRequest dietSync = new LocalDietEntrySyncItemRequest(DIET_CLIENT_ID, null, NOW, NOW);
        UserProfileEntity profile = profileEntity();
        DailyNutritionSnapshotResponse snapshot = new DailyNutritionSnapshotResponse(
                LocalDate.parse("2026-06-09"),
                2021,
                95,
                1926,
                new BigDecimal("0.50"),
                new BigDecimal("0.30"),
                new BigDecimal("25.00"),
                1,
                new BigDecimal("75.00"));
        List<FoodEntryResponse> importedDietEntries = List.of();
        List<UUID> skippedDietClientIds = List.of();
        List<LocalDietEntrySyncFailureResponse> failedDietItems = List.of();

        when(userProfileRepository.findByUserId(USER_ID))
                .thenReturn(Optional.empty(), Optional.of(profile));
        when(userProfileApplicationService.saveProfile(USER_ID, profileRequest))
                .thenReturn(new ProfilePayload(true, profileResponse()));
        when(weightApplicationService.syncLocalWeight(eq(USER_ID), eq(profile), eq(weightSync)))
                .thenReturn(Optional.of(new WeightEntryResponse(
                        UUID.randomUUID(),
                        WEIGHT_CLIENT_ID,
                        LocalDate.parse("2026-06-09"),
                        new BigDecimal("75.00"),
                        "早晨空腹",
                        NOW)));
        when(dietEntryApplicationService.syncLocalEntries(eq(USER_ID), any(SyncLocalDietEntriesRequest.class)))
                .thenReturn(new SyncLocalDietEntriesResultResponse(
                        importedDietEntries,
                        skippedDietClientIds,
                        failedDietItems,
                        List.of(snapshot)));

        SyncLocalResultResponse response = syncApplicationService.syncLocal(
                USER_ID,
                new SyncLocalRequest(profileSync, List.of(weightSync), List.of(dietSync)));

        assertThat(response.profile().status()).isEqualTo("imported");
        assertThat(response.weightEntries().importedCount()).isEqualTo(1);
        assertThat(response.weightEntries().skippedCount()).isZero();
        assertThat(response.dietEntries().importedCount()).isEqualTo(1);
        assertThat(response.dietEntries().failedItems()).isEmpty();
        assertThat(response.refreshedDates()).containsExactly(LocalDate.parse("2026-06-09"));
    }

    private SaveUserProfileRequest profileRequest() {
        return new SaveUserProfileRequest(
                Gender.FEMALE,
                25,
                new BigDecimal("181"),
                new BigDecimal("75"),
                new BigDecimal("66"),
                GoalType.LOSE_WEIGHT,
                ActivityLevel.LIGHT,
                "Asia/Shanghai",
                null);
    }

    private UserProfileResponse profileResponse() {
        return new UserProfileResponse(
                Gender.FEMALE,
                25,
                new BigDecimal("181.00"),
                new BigDecimal("75.00"),
                new BigDecimal("66.00"),
                GoalType.LOSE_WEIGHT,
                ActivityLevel.LIGHT,
                "Asia/Shanghai",
                null,
                new BigDecimal("22.90"),
                1761,
                2021,
                new BigDecimal("-0.40"));
    }

    private UserProfileEntity profileEntity() {
        UserProfileEntity profile = new UserProfileEntity();
        profile.setUserId(USER_ID);
        profile.setTimezone("Asia/Shanghai");
        profile.setDailyCalorieTargetKcal(2021);
        return profile;
    }
}
