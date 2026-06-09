package com.leanmate.diet.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.util.List;

public record SyncLocalDietEntriesRequest(
        @NotEmpty @Size(max = 200) List<LocalDietEntrySyncItemRequest> entries
) {
}
