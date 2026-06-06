package com.leanmate.common.security;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class JwtTokenService {

    private static final String HMAC_SHA256 = "HmacSHA256";
    private static final String TOKEN_TYPE_ACCESS = "access";
    private static final Base64.Encoder BASE64_URL_ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder BASE64_URL_DECODER = Base64.getUrlDecoder();
    private static final TypeReference<Map<String, Object>> CLAIMS_TYPE = new TypeReference<>() {
    };

    private final JwtProperties jwtProperties;
    private final ObjectMapper objectMapper;
    private final Clock clock;

    @Autowired
    public JwtTokenService(JwtProperties jwtProperties, ObjectMapper objectMapper) {
        this(jwtProperties, objectMapper, Clock.systemUTC());
    }

    JwtTokenService(JwtProperties jwtProperties, ObjectMapper objectMapper, Clock clock) {
        this.jwtProperties = jwtProperties;
        this.objectMapper = objectMapper;
        this.clock = clock;
    }

    public String generateAccessToken(UUID userId) {
        Instant now = clock.instant();
        Instant expiresAt = now.plusSeconds(jwtProperties.accessTokenTtlSeconds());

        Map<String, Object> header = new LinkedHashMap<>();
        header.put("alg", "HS256");
        header.put("typ", "JWT");

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("iss", jwtProperties.issuer());
        payload.put("sub", userId.toString());
        payload.put("typ", TOKEN_TYPE_ACCESS);
        payload.put("iat", now.getEpochSecond());
        payload.put("exp", expiresAt.getEpochSecond());

        String unsignedToken = encodeJson(header) + "." + encodeJson(payload);
        return unsignedToken + "." + sign(unsignedToken);
    }

    public UUID parseUserId(String token) {
        Map<String, Object> claims = parseClaims(token);
        String subject = stringClaim(claims, "sub");
        if (subject == null || subject.isBlank()) {
            throw invalidToken();
        }
        try {
            return UUID.fromString(subject);
        } catch (IllegalArgumentException exception) {
            throw invalidToken();
        }
    }

    private Map<String, Object> parseClaims(String token) {
        String[] parts = token == null ? new String[0] : token.split("\\.", -1);
        if (parts.length != 3 || parts[0].isBlank() || parts[1].isBlank() || parts[2].isBlank()) {
            throw invalidToken();
        }

        String unsignedToken = parts[0] + "." + parts[1];
        String expectedSignature = sign(unsignedToken);
        if (!MessageDigest.isEqual(
                expectedSignature.getBytes(StandardCharsets.US_ASCII),
                parts[2].getBytes(StandardCharsets.US_ASCII))) {
            throw invalidToken();
        }

        try {
            Map<String, Object> header = objectMapper.readValue(decodeBase64(parts[0]), CLAIMS_TYPE);
            if (!"HS256".equals(stringClaim(header, "alg")) || !"JWT".equals(stringClaim(header, "typ"))) {
                throw invalidToken();
            }

            Map<String, Object> claims = objectMapper.readValue(decodeBase64(parts[1]), CLAIMS_TYPE);
            validateClaims(claims);
            return claims;
        } catch (IOException exception) {
            throw invalidToken();
        }
    }

    private void validateClaims(Map<String, Object> claims) {
        if (!jwtProperties.issuer().equals(stringClaim(claims, "iss"))) {
            throw invalidToken();
        }
        if (!TOKEN_TYPE_ACCESS.equals(stringClaim(claims, "typ"))) {
            throw invalidToken();
        }

        long expiresAt = longClaim(claims, "exp");
        if (!Instant.ofEpochSecond(expiresAt).isAfter(clock.instant())) {
            throw invalidToken();
        }
    }

    private String encodeJson(Map<String, Object> value) {
        try {
            return BASE64_URL_ENCODER.encodeToString(objectMapper.writeValueAsBytes(value));
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("JWT JSON 序列化失败", exception);
        }
    }

    private byte[] decodeBase64(String value) {
        try {
            return BASE64_URL_DECODER.decode(value);
        } catch (IllegalArgumentException exception) {
            throw invalidToken();
        }
    }

    private String sign(String value) {
        try {
            Mac mac = Mac.getInstance(HMAC_SHA256);
            SecretKeySpec keySpec = new SecretKeySpec(
                    jwtProperties.secret().getBytes(StandardCharsets.UTF_8),
                    HMAC_SHA256);
            mac.init(keySpec);
            return BASE64_URL_ENCODER.encodeToString(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("JWT 签名失败", exception);
        }
    }

    private String stringClaim(Map<String, Object> claims, String name) {
        Object value = claims.get(name);
        return value instanceof String stringValue ? stringValue : null;
    }

    private long longClaim(Map<String, Object> claims, String name) {
        Object value = claims.get(name);
        if (value instanceof Number numberValue) {
            return numberValue.longValue();
        }
        throw invalidToken();
    }

    private BusinessException invalidToken() {
        return new BusinessException(ErrorCode.INVALID_TOKEN);
    }
}
