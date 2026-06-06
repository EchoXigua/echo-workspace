package com.leanmate.user.dto;

public record AuthTokenResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        long expiresIn,
        CurrentUserResponse user,
        boolean profileCompleted
) {
}
