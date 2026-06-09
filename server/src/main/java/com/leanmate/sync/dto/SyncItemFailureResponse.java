package com.leanmate.sync.dto;

import java.util.UUID;

public record SyncItemFailureResponse(
        UUID clientLocalId,
        String code,
        String message
) {
}
