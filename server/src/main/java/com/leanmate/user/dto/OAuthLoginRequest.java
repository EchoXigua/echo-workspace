package com.leanmate.user.dto;

import com.leanmate.user.domain.AuthProvider;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record OAuthLoginRequest(
        @NotNull AuthProvider provider,
        @NotBlank String identityToken,
        String authorizationCode,
        @Size(max = 128) String deviceId
) {
}
