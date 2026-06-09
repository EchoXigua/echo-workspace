package com.leanmate.sync.application;

import com.leanmate.common.exception.BusinessException;
import com.leanmate.diet.application.DietEntryApplicationService;
import com.leanmate.diet.dto.LocalDietEntrySyncFailureResponse;
import com.leanmate.diet.dto.LocalDietEntrySyncItemRequest;
import com.leanmate.diet.dto.SyncLocalDietEntriesRequest;
import com.leanmate.diet.dto.SyncLocalDietEntriesResultResponse;
import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.sync.dto.LocalProfileSyncRequest;
import com.leanmate.sync.dto.SyncCategoryResultResponse;
import com.leanmate.sync.dto.SyncItemFailureResponse;
import com.leanmate.sync.dto.SyncLocalRequest;
import com.leanmate.sync.dto.SyncLocalResultResponse;
import com.leanmate.sync.dto.SyncProfileResultResponse;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.application.UserProfileApplicationService;
import com.leanmate.user.dto.ProfilePayload;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.weight.application.WeightApplicationService;
import com.leanmate.weight.dto.SyncLocalWeightEntryRequest;
import com.leanmate.weight.dto.WeightEntryResponse;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class SyncApplicationService {

    private final CurrentUserApplicationService currentUserApplicationService;
    private final UserProfileRepository userProfileRepository;
    private final UserProfileApplicationService userProfileApplicationService;
    private final DietEntryApplicationService dietEntryApplicationService;
    private final WeightApplicationService weightApplicationService;

    public SyncApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            UserProfileApplicationService userProfileApplicationService,
            DietEntryApplicationService dietEntryApplicationService,
            WeightApplicationService weightApplicationService
    ) {
        this.currentUserApplicationService = currentUserApplicationService;
        this.userProfileRepository = userProfileRepository;
        this.userProfileApplicationService = userProfileApplicationService;
        this.dietEntryApplicationService = dietEntryApplicationService;
        this.weightApplicationService = weightApplicationService;
    }

    public SyncLocalResultResponse syncLocal(UUID userId, SyncLocalRequest request) {
        currentUserApplicationService.requireActiveUser(userId);
        SyncLocalRequest safeRequest = request == null
                ? new SyncLocalRequest(null, List.of(), List.of())
                : request;

        SyncProfileResultResponse profileResult = syncProfile(userId, safeRequest.profile());
        Set<LocalDate> refreshedDates = new TreeSet<>();
        SyncCategoryResultResponse weightResult = syncWeightEntries(
                userId,
                safeList(safeRequest.weightEntries()),
                refreshedDates);
        SyncCategoryResultResponse dietResult = syncDietEntries(
                userId,
                safeList(safeRequest.dietEntries()),
                refreshedDates);

        return new SyncLocalResultResponse(
                profileResult,
                dietResult,
                weightResult,
                List.copyOf(refreshedDates));
    }

    private SyncProfileResultResponse syncProfile(UUID userId, LocalProfileSyncRequest request) {
        if (request == null) {
            return new SyncProfileResultResponse("not_provided", null, null);
        }
        if (request.updatedAt() == null || request.data() == null) {
            return new SyncProfileResultResponse("failed", "profile.updatedAt 和 profile.data 不能为空", null);
        }

        UserProfileEntity existingProfile = userProfileRepository.findByUserId(userId).orElse(null);
        if (existingProfile != null && existingProfile.getUpdatedAt() != null
                && !existingProfile.getUpdatedAt().isBefore(request.updatedAt())) {
            return new SyncProfileResultResponse("skipped", "远端档案更新时间不早于本地数据", null);
        }

        try {
            ProfilePayload payload = userProfileApplicationService.saveProfile(userId, request.data());
            return new SyncProfileResultResponse("imported", null, payload.profile());
        } catch (BusinessException exception) {
            return new SyncProfileResultResponse("failed", exception.getMessage(), null);
        }
    }

    private SyncCategoryResultResponse syncWeightEntries(
            UUID userId,
            List<SyncLocalWeightEntryRequest> entries,
            Set<LocalDate> refreshedDates
    ) {
        if (entries.isEmpty()) {
            return emptyCategory();
        }

        UserProfileEntity profile = userProfileRepository.findByUserId(userId).orElse(null);
        List<SyncItemFailureResponse> failedItems = new ArrayList<>();
        Set<UUID> seenClientLocalIds = new HashSet<>();
        int importedCount = 0;
        int skippedCount = 0;

        for (SyncLocalWeightEntryRequest entry : entries) {
            UUID clientLocalId = entry == null ? null : entry.clientLocalId();
            if (clientLocalId == null) {
                failedItems.add(new SyncItemFailureResponse(null, "invalid_weight_entry", "clientLocalId 不能为空"));
                continue;
            }
            if (!seenClientLocalIds.add(clientLocalId)) {
                skippedCount++;
                continue;
            }
            if (profile == null) {
                failedItems.add(new SyncItemFailureResponse(clientLocalId, "profile_required", "请先完成用户档案"));
                continue;
            }

            try {
                Optional<WeightEntryResponse> importedEntry = weightApplicationService.syncLocalWeight(
                        userId,
                        profile,
                        entry);
                if (importedEntry.isPresent()) {
                    importedCount++;
                    refreshedDates.add(importedEntry.get().recordDate());
                } else {
                    skippedCount++;
                }
            } catch (BusinessException exception) {
                failedItems.add(new SyncItemFailureResponse(
                        clientLocalId,
                        "invalid_weight_entry",
                        exception.getMessage()));
            }
        }

        return new SyncCategoryResultResponse(importedCount, skippedCount, failedItems);
    }

    private SyncCategoryResultResponse syncDietEntries(
            UUID userId,
            List<LocalDietEntrySyncItemRequest> entries,
            Set<LocalDate> refreshedDates
    ) {
        if (entries.isEmpty()) {
            return emptyCategory();
        }

        List<SyncItemFailureResponse> failedItems = new ArrayList<>();
        List<LocalDietEntrySyncItemRequest> validEntries = new ArrayList<>();
        for (LocalDietEntrySyncItemRequest entry : entries) {
            if (entry == null || entry.clientLocalId() == null) {
                failedItems.add(new SyncItemFailureResponse(null, "invalid_food_entry", "clientLocalId 不能为空"));
                continue;
            }
            validEntries.add(entry);
        }

        if (validEntries.isEmpty()) {
            return new SyncCategoryResultResponse(0, 0, failedItems);
        }

        try {
            SyncLocalDietEntriesResultResponse result = dietEntryApplicationService.syncLocalEntries(
                    userId,
                    new SyncLocalDietEntriesRequest(validEntries));
            failedItems.addAll(result.failedItems().stream().map(this::toFailureResponse).toList());
            result.snapshots().stream()
                    .map(DailyNutritionSnapshotResponse::date)
                    .forEach(refreshedDates::add);

            int skippedCount = result.skippedClientLocalIds().size();
            int importedCount = Math.max(0, validEntries.size() - skippedCount - result.failedItems().size());
            return new SyncCategoryResultResponse(importedCount, skippedCount, failedItems);
        } catch (BusinessException exception) {
            failedItems.addAll(validEntries.stream()
                    .map(entry -> new SyncItemFailureResponse(
                            entry.clientLocalId(),
                            "invalid_food_entry",
                            exception.getMessage()))
                    .toList());
            return new SyncCategoryResultResponse(0, 0, failedItems);
        }
    }

    private SyncItemFailureResponse toFailureResponse(LocalDietEntrySyncFailureResponse failure) {
        return new SyncItemFailureResponse(failure.clientLocalId(), failure.code(), failure.message());
    }

    private SyncCategoryResultResponse emptyCategory() {
        return new SyncCategoryResultResponse(0, 0, List.of());
    }

    private <T> List<T> safeList(List<T> values) {
        return values == null ? List.of() : values;
    }
}
