package com.leanmate.user.application;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.user.domain.AuthProvider;
import java.io.IOException;
import java.math.BigInteger;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.Signature;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.RSAPublicKeySpec;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class AppleIdentityTokenVerifier {

    private static final URI APPLE_KEYS_URI = URI.create("https://appleid.apple.com/auth/keys");
    private static final String APPLE_ISSUER = "https://appleid.apple.com";
    private static final Base64.Decoder BASE64_URL_DECODER = Base64.getUrlDecoder();
    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
    };

    private final AppleAuthProperties appleAuthProperties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final Clock clock;

    private Map<String, Object> cachedKeys;
    private Instant cachedKeysExpiresAt = Instant.EPOCH;

    @Autowired
    public AppleIdentityTokenVerifier(AppleAuthProperties appleAuthProperties, ObjectMapper objectMapper) {
        this(
                appleAuthProperties,
                objectMapper,
                HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build(),
                Clock.systemUTC());
    }

    AppleIdentityTokenVerifier(
            AppleAuthProperties appleAuthProperties,
            ObjectMapper objectMapper,
            HttpClient httpClient,
            Clock clock
    ) {
        this.appleAuthProperties = appleAuthProperties;
        this.objectMapper = objectMapper;
        this.httpClient = httpClient;
        this.clock = clock;
    }

    public VerifiedOAuthIdentity verify(String identityToken) {
        if (!StringUtils.hasText(appleAuthProperties.clientId())) {
            throw new BusinessException(ErrorCode.INTERNAL_SERVER_ERROR, "Apple 登录配置缺失");
        }

        String[] tokenParts = identityToken == null ? new String[0] : identityToken.split("\\.", -1);
        if (tokenParts.length != 3) {
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
        }

        Map<String, Object> header = decodeJson(tokenParts[0]);
        Map<String, Object> claims = decodeJson(tokenParts[1]);
        verifySignature(tokenParts, header);
        validateClaims(claims);

        return new VerifiedOAuthIdentity(
                AuthProvider.APPLE,
                stringClaim(claims, "sub"),
                stringClaim(claims, "email"));
    }

    private void verifySignature(String[] tokenParts, Map<String, Object> header) {
        if (!"RS256".equals(stringClaim(header, "alg"))) {
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
        }

        String keyId = stringClaim(header, "kid");
        if (!StringUtils.hasText(keyId)) {
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
        }

        Map<String, Object> jwk = findJwk(keyId);
        try {
            RSAPublicKey publicKey = buildPublicKey(jwk);
            Signature signature = Signature.getInstance("SHA256withRSA");
            signature.initVerify(publicKey);
            signature.update((tokenParts[0] + "." + tokenParts[1]).getBytes(StandardCharsets.US_ASCII));
            boolean verified = signature.verify(BASE64_URL_DECODER.decode(tokenParts[2]));
            if (!verified) {
                throw new BusinessException(ErrorCode.INVALID_TOKEN);
            }
        } catch (BusinessException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new BusinessException(ErrorCode.INTERNAL_SERVER_ERROR, "Apple 登录校验失败");
        }
    }

    private void validateClaims(Map<String, Object> claims) {
        if (!APPLE_ISSUER.equals(stringClaim(claims, "iss"))) {
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
        }
        if (!audienceMatches(claims.get("aud"))) {
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
        }
        if (!StringUtils.hasText(stringClaim(claims, "sub"))) {
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
        }
        long expiresAt = longClaim(claims, "exp");
        if (!Instant.ofEpochSecond(expiresAt).isAfter(clock.instant())) {
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
        }
    }

    private boolean audienceMatches(Object audience) {
        String clientId = appleAuthProperties.clientId();
        if (audience instanceof String audienceValue) {
            return clientId.equals(audienceValue);
        }
        if (audience instanceof List<?> audienceList) {
            return audienceList.stream().anyMatch(clientId::equals);
        }
        return false;
    }

    private synchronized Map<String, Object> fetchAppleKeys() {
        Instant now = clock.instant();
        if (cachedKeys != null && cachedKeysExpiresAt.isAfter(now)) {
            return cachedKeys;
        }

        HttpRequest request = HttpRequest.newBuilder(APPLE_KEYS_URI)
                .timeout(Duration.ofSeconds(5))
                .GET()
                .build();
        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new BusinessException(ErrorCode.INTERNAL_SERVER_ERROR, "Apple 登录校验服务暂时不可用");
            }
            cachedKeys = objectMapper.readValue(response.body(), MAP_TYPE);
            cachedKeysExpiresAt = now.plus(Duration.ofHours(24));
            return cachedKeys;
        } catch (BusinessException exception) {
            throw exception;
        } catch (IOException exception) {
            throw new BusinessException(ErrorCode.INTERNAL_SERVER_ERROR, "Apple 登录校验服务暂时不可用");
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new BusinessException(ErrorCode.INTERNAL_SERVER_ERROR, "Apple 登录校验服务暂时不可用");
        }
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> findJwk(String keyId) {
        Object keysValue = fetchAppleKeys().get("keys");
        if (!(keysValue instanceof List<?> keys)) {
            throw new BusinessException(ErrorCode.INTERNAL_SERVER_ERROR, "Apple 登录校验服务返回异常");
        }
        return keys.stream()
                .filter(Map.class::isInstance)
                .map(key -> (Map<String, Object>) key)
                .filter(key -> keyId.equals(stringClaim(key, "kid")))
                .findFirst()
                .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_TOKEN));
    }

    private RSAPublicKey buildPublicKey(Map<String, Object> jwk) throws Exception {
        byte[] modulusBytes = BASE64_URL_DECODER.decode(stringClaim(jwk, "n"));
        byte[] exponentBytes = BASE64_URL_DECODER.decode(stringClaim(jwk, "e"));
        RSAPublicKeySpec keySpec = new RSAPublicKeySpec(
                new BigInteger(1, modulusBytes),
                new BigInteger(1, exponentBytes));
        return (RSAPublicKey) KeyFactory.getInstance("RSA").generatePublic(keySpec);
    }

    private Map<String, Object> decodeJson(String value) {
        try {
            return objectMapper.readValue(BASE64_URL_DECODER.decode(value), MAP_TYPE);
        } catch (IllegalArgumentException | IOException exception) {
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
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
        throw new BusinessException(ErrorCode.INVALID_TOKEN);
    }
}
