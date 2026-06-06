package com.leanmate.user.dto;

public record ProfilePayload(
        boolean profileCompleted,
        UserProfileResponse profile
) {
}
