package com.leanmate.user.dto;

import com.leanmate.user.domain.UserStatus;
import java.time.Instant;
import java.util.UUID;

public record CurrentUserResponse(
        UUID id,
        String nickname,
        String avatarUrl,
        UserStatus status,
        boolean profileCompleted,
        Instant createdAt
) {
}
