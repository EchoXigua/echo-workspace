package com.leanmate.sync.dto;

import com.leanmate.diet.dto.LocalDietEntrySyncItemRequest;
import com.leanmate.weight.dto.SyncLocalWeightEntryRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record SyncLocalRequest(
        @Valid LocalProfileSyncRequest profile,
        @Size(max = 200) List<@NotNull @Valid SyncLocalWeightEntryRequest> weightEntries,
        @Size(max = 200) List<@NotNull @Valid LocalDietEntrySyncItemRequest> dietEntries
) {
}
