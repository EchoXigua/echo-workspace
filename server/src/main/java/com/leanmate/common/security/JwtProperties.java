package com.leanmate.common.security;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "leanmate.jwt")
public record JwtProperties(
        @NotBlank String issuer,
        @NotBlank String secret,
        @Positive long accessTokenTtlSeconds,
        @Positive long refreshTokenTtlDays
) {
}
