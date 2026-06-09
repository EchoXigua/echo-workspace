package com.leanmate.diet.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.diet.domain.FoodEntryCalculator;
import com.leanmate.diet.domain.FoodEntrySourceType;
import com.leanmate.diet.domain.FoodEntryStatus;
import com.leanmate.diet.domain.MealType;
import com.leanmate.diet.domain.NutritionDataValidator;
import com.leanmate.diet.dto.FoodEntrySaveResultResponse;
import com.leanmate.diet.dto.LocalDietEntrySyncItemRequest;
import com.leanmate.diet.dto.SaveFoodEntryRequest;
import com.leanmate.diet.dto.SaveFoodItemRequest;
import com.leanmate.diet.dto.SyncLocalDietEntriesRequest;
import com.leanmate.diet.dto.SyncLocalDietEntriesResultResponse;
import com.leanmate.diet.repository.FoodEntryEntity;
import com.leanmate.diet.repository.FoodEntryRepository;
import com.leanmate.diet.repository.FoodItemEntity;
import com.leanmate.diet.repository.FoodItemRepository;
import com.leanmate.food.repository.FoodCatalogRepository;
import com.leanmate.retention.application.RetentionApplicationService;
import com.leanmate.stats.application.DailyNutritionSnapshotApplicationService;
import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.repository.UserEntity;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.mockito.ArgumentCaptor;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DietEntryApplicationServiceTests {

    private static final UUID USER_ID = UUID.fromString("11111111-2222-3333-4444-555555555555");
    private static final UUID ENTRY_ID = UUID.fromString("aaaaaaaa-1111-2222-3333-444444444444");
    private static final UUID CLIENT_LOCAL_ID = UUID.fromString("cccccccc-1111-2222-3333-444444444444");
    private static final UUID FOOD_ID = UUID.fromString("10000000-0000-0000-0000-000000000011");

    private CurrentUserApplicationService currentUserApplicationService;
    private UserProfileRepository userProfileRepository;
    private FoodEntryRepository foodEntryRepository;
    private FoodItemRepository foodItemRepository;
    private FoodCatalogRepository foodCatalogRepository;
    private DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService;
    private RetentionApplicationService retentionApplicationService;
    private DietEntryApplicationService dietEntryApplicationService;

    @BeforeEach
    void setUp() {
        currentUserApplicationService = mock(CurrentUserApplicationService.class);
        userProfileRepository = mock(UserProfileRepository.class);
        foodEntryRepository = mock(FoodEntryRepository.class);
        foodItemRepository = mock(FoodItemRepository.class);
        foodCatalogRepository = mock(FoodCatalogRepository.class);
        dailyNutritionSnapshotApplicationService = mock(DailyNutritionSnapshotApplicationService.class);
        retentionApplicationService = mock(RetentionApplicationService.class);
        dietEntryApplicationService = new DietEntryApplicationService(
                currentUserApplicationService,
                userProfileRepository,
                foodEntryRepository,
                foodItemRepository,
                foodCatalogRepository,
                new FoodEntryCalculator(),
                new NutritionDataValidator(),
                dailyNutritionSnapshotApplicationService,
                retentionApplicationService,
                Clock.fixed(Instant.parse("2026-06-07T00:00:00Z"), ZoneOffset.UTC));

        when(currentUserApplicationService.requireActiveUser(USER_ID)).thenReturn(new UserEntity());
        when(userProfileRepository.findByUserId(USER_ID)).thenReturn(Optional.of(profile()));
    }

    @Test
    void createConfirmedEntryAndRefreshSnapshot() {
        SaveFoodEntryRequest request = request(LocalDate.parse("2026-06-07"));
        DailyNutritionSnapshotResponse snapshot = snapshot(LocalDate.parse("2026-06-07"));
        when(foodEntryRepository.save(any(FoodEntryEntity.class))).thenAnswer(invocation -> {
            FoodEntryEntity entry = invocation.getArgument(0);
            entry.setId(ENTRY_ID);
            return entry;
        });
        when(foodItemRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(dailyNutritionSnapshotApplicationService.recalculateDietTotals(
                USER_ID,
                request.mealDate(),
                1800))
                .thenReturn(snapshot);

        FoodEntrySaveResultResponse response = dietEntryApplicationService.createEntry(USER_ID, request);

        assertThat(response.entry().status()).isEqualTo(FoodEntryStatus.CONFIRMED);
        assertThat(response.entry().totalCaloriesKcal()).isEqualTo(450);
        assertThat(response.entry().totalProteinG()).isEqualByComparingTo("33.50");
        assertThat(response.entry().items()).hasSize(2);
        assertThat(response.today()).isEqualTo(snapshot);
        verify(foodItemRepository).deleteByFoodEntryId(ENTRY_ID);
        verify(retentionApplicationService).getStreak(USER_ID);
    }

    @Test
    void rejectEntryWhenNutritionDataIsUnreasonable() {
        SaveFoodEntryRequest request = invalidNutritionRequest(LocalDate.parse("2026-06-07"));

        assertThatThrownBy(() -> dietEntryApplicationService.createEntry(USER_ID, request))
                .isInstanceOf(BusinessException.class)
                .hasMessage("热量与蛋白质、脂肪、碳水估算值偏差过大")
                .extracting("errorCode")
                .isEqualTo(ErrorCode.BAD_REQUEST);
        verifyNoInteractions(dailyNutritionSnapshotApplicationService);
    }

    @Test
    void createEntryPersistsFoodCatalogReferenceAndNutritionSource() {
        SaveFoodEntryRequest request = requestWithFoodId(LocalDate.parse("2026-06-07"));
        when(foodCatalogRepository.existsById(FOOD_ID)).thenReturn(true);
        when(foodEntryRepository.save(any(FoodEntryEntity.class))).thenAnswer(invocation -> {
            FoodEntryEntity entry = invocation.getArgument(0);
            entry.setId(ENTRY_ID);
            return entry;
        });
        when(foodItemRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(dailyNutritionSnapshotApplicationService.recalculateDietTotals(
                USER_ID,
                request.mealDate(),
                1800))
                .thenReturn(snapshot(LocalDate.parse("2026-06-07")));

        FoodEntrySaveResultResponse response = dietEntryApplicationService.createEntry(USER_ID, request);

        assertThat(response.entry().items()).hasSize(1);
        assertThat(response.entry().items().get(0).foodId()).isEqualTo(FOOD_ID);
        assertThat(response.entry().items().get(0).nutritionSource().value()).isEqualTo("food_db");
    }

    @Test
    void syncLocalEntriesImportsNewEntryAndRefreshesSnapshots() {
        SaveFoodEntryRequest entryRequest = request(LocalDate.parse("2026-06-07"));
        SyncLocalDietEntriesRequest request = syncRequest(CLIENT_LOCAL_ID, entryRequest);
        DailyNutritionSnapshotResponse snapshot = snapshot(LocalDate.parse("2026-06-07"));

        when(foodEntryRepository.findByUserIdAndClientLocalId(USER_ID, CLIENT_LOCAL_ID))
                .thenReturn(Optional.empty());
        when(foodEntryRepository.save(any(FoodEntryEntity.class))).thenAnswer(invocation -> {
            FoodEntryEntity entry = invocation.getArgument(0);
            entry.setId(ENTRY_ID);
            return entry;
        });
        when(foodItemRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(dailyNutritionSnapshotApplicationService.recalculateDietTotals(
                USER_ID,
                entryRequest.mealDate(),
                1800))
                .thenReturn(snapshot);

        SyncLocalDietEntriesResultResponse response = dietEntryApplicationService.syncLocalEntries(USER_ID, request);

        assertThat(response.importedEntries()).hasSize(1);
        assertThat(response.importedEntries().get(0).totalCaloriesKcal()).isEqualTo(450);
        assertThat(response.skippedClientLocalIds()).isEmpty();
        assertThat(response.failedItems()).isEmpty();
        assertThat(response.snapshots()).containsExactly(snapshot);

        ArgumentCaptor<FoodEntryEntity> entryCaptor = ArgumentCaptor.forClass(FoodEntryEntity.class);
        verify(foodEntryRepository).save(entryCaptor.capture());
        assertThat(entryCaptor.getValue().getClientLocalId()).isEqualTo(CLIENT_LOCAL_ID);
        verify(retentionApplicationService).getStreak(USER_ID);
    }

    @Test
    void syncLocalEntriesSkipsExistingClientLocalId() {
        FoodEntryEntity existingEntry = existingEntry(USER_ID, LocalDate.parse("2026-06-07"));
        existingEntry.setClientLocalId(CLIENT_LOCAL_ID);
        FoodItemEntity existingItem = existingItem();
        DailyNutritionSnapshotResponse snapshot = snapshot(LocalDate.parse("2026-06-07"));

        when(foodEntryRepository.findByUserIdAndClientLocalId(USER_ID, CLIENT_LOCAL_ID))
                .thenReturn(Optional.of(existingEntry));
        when(foodItemRepository.findByFoodEntryIdOrderBySortOrderAsc(ENTRY_ID))
                .thenReturn(List.of(existingItem));
        when(dailyNutritionSnapshotApplicationService.recalculateDietTotals(
                USER_ID,
                LocalDate.parse("2026-06-07"),
                1800))
                .thenReturn(snapshot);

        SyncLocalDietEntriesResultResponse response = dietEntryApplicationService.syncLocalEntries(
                USER_ID,
                syncRequest(CLIENT_LOCAL_ID, request(LocalDate.parse("2026-06-07"))));

        assertThat(response.importedEntries()).hasSize(1);
        assertThat(response.skippedClientLocalIds()).containsExactly(CLIENT_LOCAL_ID);
        assertThat(response.failedItems()).isEmpty();
        assertThat(response.snapshots()).containsExactly(snapshot);
        verify(foodEntryRepository, never()).save(any(FoodEntryEntity.class));
    }

    @Test
    void syncLocalEntriesReturnsFailedItemWhenEntryIsInvalid() {
        SaveFoodEntryRequest invalidEntry = new SaveFoodEntryRequest(
                null,
                LocalDate.parse("2026-06-07"),
                MealType.LUNCH,
                FoodEntrySourceType.MANUAL,
                null,
                null,
                List.of());

        when(foodEntryRepository.findByUserIdAndClientLocalId(USER_ID, CLIENT_LOCAL_ID))
                .thenReturn(Optional.empty());

        SyncLocalDietEntriesResultResponse response = dietEntryApplicationService.syncLocalEntries(
                USER_ID,
                syncRequest(CLIENT_LOCAL_ID, invalidEntry));

        assertThat(response.importedEntries()).isEmpty();
        assertThat(response.skippedClientLocalIds()).isEmpty();
        assertThat(response.failedItems()).hasSize(1);
        assertThat(response.failedItems().get(0).clientLocalId()).isEqualTo(CLIENT_LOCAL_ID);
        assertThat(response.failedItems().get(0).code()).isEqualTo("invalid_food_entry");
        assertThat(response.snapshots()).isEmpty();
        verify(foodEntryRepository, never()).save(any(FoodEntryEntity.class));
        verifyNoInteractions(dailyNutritionSnapshotApplicationService);
    }

    @Test
    void updateEntryAndRefreshOldAndNewDateWhenMealDateChanges() {
        FoodEntryEntity entry = existingEntry(USER_ID, LocalDate.parse("2026-06-06"));
        FoodItemEntity existingItem = new FoodItemEntity();
        existingItem.setId(UUID.fromString("bbbbbbbb-1111-2222-3333-444444444444"));
        SaveFoodEntryRequest request = request(LocalDate.parse("2026-06-07"));

        when(foodEntryRepository.findById(ENTRY_ID)).thenReturn(Optional.of(entry));
        when(foodItemRepository.findByFoodEntryIdOrderBySortOrderAsc(ENTRY_ID)).thenReturn(List.of(existingItem));
        when(foodEntryRepository.save(entry)).thenReturn(entry);
        when(foodItemRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(dailyNutritionSnapshotApplicationService.recalculateDietTotals(
                USER_ID,
                LocalDate.parse("2026-06-07"),
                1800))
                .thenReturn(snapshot(LocalDate.parse("2026-06-07")));

        FoodEntrySaveResultResponse response = dietEntryApplicationService.updateEntry(USER_ID, ENTRY_ID, request);

        assertThat(response.entry().mealDate()).isEqualTo(LocalDate.parse("2026-06-07"));
        verify(dailyNutritionSnapshotApplicationService).recalculateDietTotals(
                USER_ID,
                LocalDate.parse("2026-06-06"),
                1800);
        verify(dailyNutritionSnapshotApplicationService).recalculateDietTotals(
                USER_ID,
                LocalDate.parse("2026-06-07"),
                1800);
    }

    @Test
    void rejectDeletingOtherUserEntry() {
        FoodEntryEntity entry = existingEntry(UUID.fromString("99999999-9999-9999-9999-999999999999"),
                LocalDate.parse("2026-06-07"));
        when(foodEntryRepository.findById(ENTRY_ID)).thenReturn(Optional.of(entry));

        assertThatThrownBy(() -> dietEntryApplicationService.deleteEntry(USER_ID, ENTRY_ID))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.FORBIDDEN);
        verifyNoInteractions(dailyNutritionSnapshotApplicationService);
    }

    private SaveFoodEntryRequest request(LocalDate mealDate) {
        return new SaveFoodEntryRequest(
                null,
                mealDate,
                MealType.LUNCH,
                FoodEntrySourceType.MANUAL,
                "  午餐  ",
                null,
                List.of(
                        new SaveFoodItemRequest(
                                null,
                                "鸡胸肉",
                                "150g",
                                new BigDecimal("150"),
                                250,
                                new BigDecimal("31.5"),
                                new BigDecimal("5"),
                                new BigDecimal("0"),
                                null,
                                true),
                        new SaveFoodItemRequest(
                                null,
                                "米饭",
                                "一碗",
                                null,
                                200,
                                new BigDecimal("2"),
                                new BigDecimal("0.5"),
                                new BigDecimal("45"),
                                null,
                                false)));
    }

    private SyncLocalDietEntriesRequest syncRequest(UUID clientLocalId, SaveFoodEntryRequest entry) {
        return new SyncLocalDietEntriesRequest(List.of(new LocalDietEntrySyncItemRequest(
                clientLocalId,
                entry,
                Instant.parse("2026-06-07T01:00:00Z"),
                Instant.parse("2026-06-07T01:05:00Z"))));
    }

    private SaveFoodEntryRequest requestWithFoodId(LocalDate mealDate) {
        return new SaveFoodEntryRequest(
                null,
                mealDate,
                MealType.LUNCH,
                FoodEntrySourceType.MANUAL,
                null,
                null,
                List.of(new SaveFoodItemRequest(
                        null,
                        "苹果",
                        "1个中等大小",
                        new BigDecimal("180"),
                        94,
                        new BigDecimal("0.5"),
                        new BigDecimal("0.4"),
                        new BigDecimal("24.8"),
                        null,
                        false,
                        FOOD_ID,
                        null)));
    }

    private SaveFoodEntryRequest invalidNutritionRequest(LocalDate mealDate) {
        return new SaveFoodEntryRequest(
                null,
                mealDate,
                MealType.LUNCH,
                FoodEntrySourceType.MANUAL,
                null,
                null,
                List.of(new SaveFoodItemRequest(
                        null,
                        "离谱食物",
                        "1份",
                        new BigDecimal("200"),
                        100,
                        new BigDecimal("100"),
                        new BigDecimal("50"),
                        new BigDecimal("200"),
                        null,
                        true)));
    }

    private FoodEntryEntity existingEntry(UUID userId, LocalDate mealDate) {
        FoodEntryEntity entry = new FoodEntryEntity();
        entry.setId(ENTRY_ID);
        entry.setUserId(userId);
        entry.setMealDate(mealDate);
        entry.setMealType(MealType.LUNCH.value());
        entry.setSourceType(FoodEntrySourceType.MANUAL.value());
        entry.setStatus(FoodEntryStatus.CONFIRMED.value());
        entry.setTotalCaloriesKcal(450);
        entry.setTotalProteinG(new BigDecimal("33.50"));
        entry.setTotalFatG(new BigDecimal("5.50"));
        entry.setTotalCarbsG(new BigDecimal("45.00"));
        return entry;
    }

    private FoodItemEntity existingItem() {
        FoodItemEntity item = new FoodItemEntity();
        item.setId(UUID.fromString("bbbbbbbb-1111-2222-3333-444444444444"));
        item.setFoodEntryId(ENTRY_ID);
        item.setName("鸡胸肉");
        item.setCaloriesKcal(250);
        return item;
    }

    private UserProfileEntity profile() {
        UserProfileEntity profile = new UserProfileEntity();
        profile.setUserId(USER_ID);
        profile.setTimezone("Asia/Shanghai");
        profile.setDailyCalorieTargetKcal(1800);
        return profile;
    }

    private DailyNutritionSnapshotResponse snapshot(LocalDate date) {
        return new DailyNutritionSnapshotResponse(
                date,
                1800,
                450,
                1350,
                new BigDecimal("33.50"),
                new BigDecimal("5.50"),
                new BigDecimal("45.00"),
                1,
                null);
    }
}
