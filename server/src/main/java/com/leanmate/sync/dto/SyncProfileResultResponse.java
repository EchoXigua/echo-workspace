package com.leanmate.sync.dto;

import com.leanmate.user.dto.UserProfileResponse;

public record SyncProfileResultResponse(
        String status,
        String message,
        UserProfileResponse profile
) {
}
