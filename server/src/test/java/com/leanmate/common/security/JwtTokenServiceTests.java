package com.leanmate.common.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class JwtTokenServiceTests {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void generateAndParseAccessToken() {
        UUID userId = UUID.fromString("11111111-1111-1111-1111-111111111111");
        JwtTokenService tokenService = tokenService(Instant.parse("2026-06-06T00:00:00Z"), 3600);

        String token = tokenService.generateAccessToken(userId);

        assertThat(tokenService.parseUserId(token)).isEqualTo(userId);
    }

    @Test
    void rejectTamperedToken() {
        UUID userId = UUID.fromString("22222222-2222-2222-2222-222222222222");
        JwtTokenService tokenService = tokenService(Instant.parse("2026-06-06T00:00:00Z"), 3600);
        String token = tokenService.generateAccessToken(userId);
        String tamperedToken = token.substring(0, token.length() - 2) + "xx";

        assertThatThrownBy(() -> tokenService.parseUserId(tamperedToken))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.INVALID_TOKEN);
    }

    @Test
    void rejectExpiredToken() {
        UUID userId = UUID.fromString("33333333-3333-3333-3333-333333333333");
        JwtProperties jwtProperties = properties(1);
        JwtTokenService generator = tokenService(jwtProperties, Instant.parse("2026-06-06T00:00:00Z"));
        JwtTokenService parser = tokenService(jwtProperties, Instant.parse("2026-06-06T00:00:02Z"));

        String token = generator.generateAccessToken(userId);

        assertThatThrownBy(() -> parser.parseUserId(token))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.INVALID_TOKEN);
    }

    private JwtTokenService tokenService(Instant now, long accessTokenTtlSeconds) {
        return tokenService(properties(accessTokenTtlSeconds), now);
    }

    private JwtTokenService tokenService(JwtProperties jwtProperties, Instant now) {
        return new JwtTokenService(jwtProperties, objectMapper, Clock.fixed(now, ZoneOffset.UTC));
    }

    private JwtProperties properties(long accessTokenTtlSeconds) {
        return new JwtProperties(
                "leanmate-test",
                "leanmate-test-jwt-secret-with-enough-length",
                accessTokenTtlSeconds,
                30);
    }
}
