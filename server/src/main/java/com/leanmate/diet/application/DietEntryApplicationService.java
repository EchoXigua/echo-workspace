package com.leanmate.diet.application;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.diet.domain.FoodEntryCalculator;
import com.leanmate.diet.domain.FoodEntryStatus;
import com.leanmate.diet.domain.FoodEntryTotals;
import com.leanmate.diet.domain.FoodEntrySourceType;
import com.leanmate.diet.domain.MealType;
import com.leanmate.diet.domain.NutritionDataValidator;
import com.leanmate.diet.dto.FoodEntryResponse;
import com.leanmate.diet.dto.FoodEntrySaveResultResponse;
import com.leanmate.diet.dto.FoodItemResponse;
import com.leanmate.diet.dto.LocalDietEntrySyncFailureResponse;
import com.leanmate.diet.dto.LocalDietEntrySyncItemRequest;
import com.leanmate.diet.dto.SaveFoodEntryRequest;
import com.leanmate.diet.dto.SaveFoodItemRequest;
import com.leanmate.diet.dto.SyncLocalDietEntriesRequest;
import com.leanmate.diet.dto.SyncLocalDietEntriesResultResponse;
import com.leanmate.diet.repository.FoodEntryEntity;
import com.leanmate.diet.repository.FoodEntryRepository;
import com.leanmate.diet.repository.FoodItemEntity;
import com.leanmate.diet.repository.FoodItemRepository;
import com.leanmate.stats.application.DailyNutritionSnapshotApplicationService;
import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.DateTimeException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class DietEntryApplicationService {

    private final CurrentUserApplicationService currentUserApplicationService;
    private final UserProfileRepository userProfileRepository;
    private final FoodEntryRepository foodEntryRepository;
    private final FoodItemRepository foodItemRepository;
    private final FoodEntryCalculator foodEntryCalculator;
    private final NutritionDataValidator nutritionDataValidator;
    private final DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService;
    private final Clock clock;

    @Autowired
    public DietEntryApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            FoodEntryRepository foodEntryRepository,
            FoodItemRepository foodItemRepository,
            FoodEntryCalculator foodEntryCalculator,
            NutritionDataValidator nutritionDataValidator,
            DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService
    ) {
        this(
                currentUserApplicationService,
                userProfileRepository,
                foodEntryRepository,
                foodItemRepository,
                foodEntryCalculator,
                nutritionDataValidator,
                dailyNutritionSnapshotApplicationService,
                Clock.systemUTC());
    }

    DietEntryApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            FoodEntryRepository foodEntryRepository,
            FoodItemRepository foodItemRepository,
            FoodEntryCalculator foodEntryCalculator,
            NutritionDataValidator nutritionDataValidator,
            DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService,
            Clock clock
    ) {
        this.currentUserApplicationService = currentUserApplicationService;
        this.userProfileRepository = userProfileRepository;
        this.foodEntryRepository = foodEntryRepository;
        this.foodItemRepository = foodItemRepository;
        this.foodEntryCalculator = foodEntryCalculator;
        this.nutritionDataValidator = nutritionDataValidator;
        this.dailyNutritionSnapshotApplicationService = dailyNutritionSnapshotApplicationService;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public List<FoodEntryResponse> listEntries(UUID userId, LocalDate date) {
        currentUserApplicationService.requireActiveUser(userId);
        if (date == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "date 不能为空");
        }
        return foodEntryRepository.findByUserIdAndMealDateAndStatusOrderByCreatedAtAsc(
                        userId,
                        date,
                        FoodEntryStatus.CONFIRMED.value())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public FoodEntrySaveResultResponse createEntry(UUID userId, SaveFoodEntryRequest request) {
        currentUserApplicationService.requireActiveUser(userId);
        UserProfileEntity profile = requireProfile(userId);
        validateMealDate(request.mealDate(), profile);
        nutritionDataValidator.validate(request.items());

        FoodEntryEntity entry = new FoodEntryEntity();
        applyRequest(entry, userId, request, foodEntryCalculator.calculate(request.items()));
        FoodEntryEntity savedEntry = foodEntryRepository.save(entry);
        List<FoodItemEntity> savedItems = replaceItems(savedEntry.getId(), request.items(), Set.of());

        DailyNutritionSnapshotResponse snapshot = refreshSnapshot(userId, request.mealDate(), profile);
        return new FoodEntrySaveResultResponse(toResponse(savedEntry, savedItems), snapshot);
    }

    @Transactional
    public SyncLocalDietEntriesResultResponse syncLocalEntries(
            UUID userId,
            SyncLocalDietEntriesRequest request
    ) {
        currentUserApplicationService.requireActiveUser(userId);
        UserProfileEntity profile = requireProfile(userId);

        List<FoodEntryResponse> importedEntries = new ArrayList<>();
        List<UUID> skippedClientLocalIds = new ArrayList<>();
        List<LocalDietEntrySyncFailureResponse> failedItems = new ArrayList<>();
        Set<LocalDate> affectedDates = new TreeSet<>();
        Set<UUID> seenClientLocalIds = new HashSet<>();

        for (LocalDietEntrySyncItemRequest item : request.entries()) {
            if (item == null || item.clientLocalId() == null) {
                throw new BusinessException(ErrorCode.BAD_REQUEST, "clientLocalId 不能为空");
            }

            UUID clientLocalId = item.clientLocalId();
            if (!seenClientLocalIds.add(clientLocalId)) {
                skippedClientLocalIds.add(clientLocalId);
                continue;
            }

            FoodEntryEntity existingEntry = foodEntryRepository
                    .findByUserIdAndClientLocalId(userId, clientLocalId)
                    .orElse(null);
            if (existingEntry != null) {
                importedEntries.add(toResponse(existingEntry));
                skippedClientLocalIds.add(clientLocalId);
                affectedDates.add(existingEntry.getMealDate());
                continue;
            }

            try {
                validateSyncItem(item, profile);

                SaveFoodEntryRequest entryRequest = item.entry();
                FoodEntryEntity entry = new FoodEntryEntity();
                applyRequest(entry, userId, entryRequest, foodEntryCalculator.calculate(entryRequest.items()));
                entry.setClientLocalId(clientLocalId);
                FoodEntryEntity savedEntry = foodEntryRepository.save(entry);
                List<FoodItemEntity> savedItems = replaceItems(savedEntry.getId(), entryRequest.items(), Set.of());

                importedEntries.add(toResponse(savedEntry, savedItems));
                affectedDates.add(entryRequest.mealDate());
            } catch (BusinessException exception) {
                failedItems.add(new LocalDietEntrySyncFailureResponse(
                        clientLocalId,
                        "invalid_food_entry",
                        exception.getMessage()));
            }
        }

        List<DailyNutritionSnapshotResponse> snapshots = affectedDates.stream()
                .map(date -> refreshSnapshot(userId, date, profile))
                .toList();
        return new SyncLocalDietEntriesResultResponse(
                importedEntries,
                skippedClientLocalIds,
                failedItems,
                snapshots);
    }

    @Transactional
    public FoodEntrySaveResultResponse updateEntry(UUID userId, UUID entryId, SaveFoodEntryRequest request) {
        currentUserApplicationService.requireActiveUser(userId);
        UserProfileEntity profile = requireProfile(userId);
        validateMealDate(request.mealDate(), profile);
        nutritionDataValidator.validate(request.items());

        FoodEntryEntity entry = requireEditableEntry(userId, entryId);
        LocalDate oldMealDate = entry.getMealDate();
        Set<UUID> existingItemIds = foodItemRepository.findByFoodEntryIdOrderBySortOrderAsc(entryId)
                .stream()
                .map(FoodItemEntity::getId)
                .collect(Collectors.toUnmodifiableSet());

        applyRequest(entry, userId, request, foodEntryCalculator.calculate(request.items()));
        FoodEntryEntity savedEntry = foodEntryRepository.save(entry);
        List<FoodItemEntity> savedItems = replaceItems(savedEntry.getId(), request.items(), existingItemIds);

        if (!oldMealDate.equals(request.mealDate())) {
            refreshSnapshot(userId, oldMealDate, profile);
        }
        DailyNutritionSnapshotResponse snapshot = refreshSnapshot(userId, request.mealDate(), profile);
        return new FoodEntrySaveResultResponse(toResponse(savedEntry, savedItems), snapshot);
    }

    @Transactional
    public void deleteEntry(UUID userId, UUID entryId) {
        currentUserApplicationService.requireActiveUser(userId);
        UserProfileEntity profile = requireProfile(userId);
        FoodEntryEntity entry = requireEditableEntry(userId, entryId);

        entry.setStatus(FoodEntryStatus.DELETED.value());
        entry.setDeletedAt(Instant.now(clock));
        foodEntryRepository.save(entry);
        refreshSnapshot(userId, entry.getMealDate(), profile);
    }

    private void validateSyncItem(LocalDietEntrySyncItemRequest item, UserProfileEntity profile) {
        if (item.createdAt() == null) {
            throw invalidSyncItem("createdAt 不能为空");
        }
        if (item.updatedAt() == null) {
            throw invalidSyncItem("updatedAt 不能为空");
        }
        if (item.entry() == null) {
            throw invalidSyncItem("entry 不能为空");
        }

        SaveFoodEntryRequest request = item.entry();
        if (request.mealDate() == null) {
            throw invalidSyncItem("mealDate 不能为空");
        }
        if (request.mealType() == null) {
            throw invalidSyncItem("mealType 不能为空");
        }
        if (request.sourceType() == null) {
            throw invalidSyncItem("sourceType 不能为空");
        }
        if (request.rawText() != null && request.rawText().length() > 1000) {
            throw invalidSyncItem("rawText 长度不能超过 1000");
        }
        if (request.items() == null || request.items().isEmpty()) {
            throw invalidSyncItem("items 不能为空");
        }

        nutritionDataValidator.validate(request.items());
        validateMealDate(request.mealDate(), profile);
    }

    private BusinessException invalidSyncItem(String message) {
        return new BusinessException(ErrorCode.BAD_REQUEST, message);
    }

    private void applyRequest(
            FoodEntryEntity entry,
            UUID userId,
            SaveFoodEntryRequest request,
            FoodEntryTotals totals
    ) {
        entry.setUserId(userId);
        entry.setRecognitionTaskId(request.recognitionTaskId());
        entry.setMealDate(request.mealDate());
        entry.setMealType(request.mealType().value());
        entry.setSourceType(request.sourceType().value());
        entry.setRawText(trimToNull(request.rawText()));
        entry.setImageUrl(trimToNull(request.imageUrl()));
        entry.setStatus(FoodEntryStatus.CONFIRMED.value());
        entry.setTotalCaloriesKcal(totals.caloriesKcal());
        entry.setTotalProteinG(totals.proteinG());
        entry.setTotalFatG(totals.fatG());
        entry.setTotalCarbsG(totals.carbsG());
        if (entry.getConfirmedAt() == null) {
            entry.setConfirmedAt(Instant.now(clock));
        }
        entry.setDeletedAt(null);
    }

    private List<FoodItemEntity> replaceItems(
            UUID foodEntryId,
            List<SaveFoodItemRequest> requests,
            Set<UUID> existingItemIds
    ) {
        foodItemRepository.deleteByFoodEntryId(foodEntryId);
        List<FoodItemEntity> items = IntStream.range(0, requests.size())
                .mapToObj(index -> toEntity(foodEntryId, requests.get(index), index, existingItemIds))
                .toList();
        return foodItemRepository.saveAll(items);
    }

    private FoodItemEntity toEntity(
            UUID foodEntryId,
            SaveFoodItemRequest request,
            int sortOrder,
            Set<UUID> existingItemIds
    ) {
        FoodItemEntity item = new FoodItemEntity();
        if (request.id() != null && existingItemIds.contains(request.id())) {
            item.setId(request.id());
        }
        item.setFoodEntryId(foodEntryId);
        item.setName(request.name().trim());
        item.setQuantityText(trimToNull(request.quantityText()));
        item.setWeightG(scale(request.weightG(), 2));
        item.setCaloriesKcal(request.caloriesKcal());
        item.setProteinG(scale(request.proteinG(), 2));
        item.setFatG(scale(request.fatG(), 2));
        item.setCarbsG(scale(request.carbsG(), 2));
        item.setConfidence(scale(request.confidence(), 4));
        item.setUserEdited(Boolean.TRUE.equals(request.userEdited()));
        item.setSortOrder(sortOrder);
        return item;
    }

    private FoodEntryEntity requireEditableEntry(UUID userId, UUID entryId) {
        FoodEntryEntity entry = foodEntryRepository.findById(entryId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND));
        if (!entry.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        if (FoodEntryStatus.DELETED.value().equals(entry.getStatus())) {
            throw new BusinessException(ErrorCode.NOT_FOUND);
        }
        return entry;
    }

    private DailyNutritionSnapshotResponse refreshSnapshot(
            UUID userId,
            LocalDate mealDate,
            UserProfileEntity profile
    ) {
        return dailyNutritionSnapshotApplicationService.recalculateDietTotals(
                userId,
                mealDate,
                profile.getDailyCalorieTargetKcal());
    }

    private UserProfileEntity requireProfile(UUID userId) {
        return userProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.BAD_REQUEST, "请先完成用户档案"));
    }

    private void validateMealDate(LocalDate mealDate, UserProfileEntity profile) {
        LocalDate today = LocalDate.now(clock.withZone(zoneId(profile)));
        if (mealDate.isAfter(today)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "饮食记录日期不能晚于今天");
        }
    }

    private ZoneId zoneId(UserProfileEntity profile) {
        try {
            return ZoneId.of(profile.getTimezone());
        } catch (DateTimeException exception) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "timezone 无效");
        }
    }

    private FoodEntryResponse toResponse(FoodEntryEntity entry) {
        return toResponse(entry, foodItemRepository.findByFoodEntryIdOrderBySortOrderAsc(entry.getId()));
    }

    private FoodEntryResponse toResponse(FoodEntryEntity entry, List<FoodItemEntity> items) {
        return new FoodEntryResponse(
                entry.getId(),
                entry.getRecognitionTaskId(),
                entry.getMealDate(),
                MealType.fromValue(entry.getMealType()),
                FoodEntrySourceType.fromValue(entry.getSourceType()),
                entry.getRawText(),
                entry.getImageUrl(),
                FoodEntryStatus.fromValue(entry.getStatus()),
                entry.getTotalCaloriesKcal(),
                entry.getTotalProteinG(),
                entry.getTotalFatG(),
                entry.getTotalCarbsG(),
                items.stream().map(this::toItemResponse).toList(),
                entry.getCreatedAt());
    }

    private FoodItemResponse toItemResponse(FoodItemEntity item) {
        return new FoodItemResponse(
                item.getId(),
                item.getName(),
                item.getQuantityText(),
                item.getWeightG(),
                item.getCaloriesKcal(),
                item.getProteinG(),
                item.getFatG(),
                item.getCarbsG(),
                item.getConfidence(),
                Boolean.TRUE.equals(item.getUserEdited()));
    }

    private BigDecimal scale(BigDecimal value, int scale) {
        if (value == null) {
            return null;
        }
        return value.setScale(scale, RoundingMode.HALF_UP);
    }

    private String trimToNull(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        return value.trim();
    }
}
