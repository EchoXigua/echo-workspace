package com.leanmate.sync.dto;

import com.leanmate.user.dto.SaveUserProfileRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;

public record LocalProfileSyncRequest(
        @NotNull UUID clientLocalId,
        @NotNull Instant updatedAt,
        @NotNull @Valid SaveUserProfileRequest data
) {
}
