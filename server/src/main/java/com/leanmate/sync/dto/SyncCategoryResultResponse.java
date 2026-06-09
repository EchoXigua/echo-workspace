package com.leanmate.sync.dto;

import java.util.List;

public record SyncCategoryResultResponse(
        int importedCount,
        int skippedCount,
        List<SyncItemFailureResponse> failedItems
) {
}
