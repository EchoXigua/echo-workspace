package com.leanmate.sync.dto;

import java.time.LocalDate;
import java.util.List;

public record SyncLocalResultResponse(
        SyncProfileResultResponse profile,
        SyncCategoryResultResponse dietEntries,
        SyncCategoryResultResponse weightEntries,
        List<LocalDate> refreshedDates
) {
}
