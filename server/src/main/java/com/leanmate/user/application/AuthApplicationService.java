package com.leanmate.user.application;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.common.security.JwtProperties;
import com.leanmate.common.security.JwtTokenService;
import com.leanmate.user.domain.UserStatus;
import com.leanmate.user.dto.AuthTokenResponse;
import com.leanmate.user.dto.LogoutRequest;
import com.leanmate.user.dto.OAuthLoginRequest;
import com.leanmate.user.dto.RefreshTokenRequest;
import com.leanmate.user.repository.RefreshTokenEntity;
import com.leanmate.user.repository.RefreshTokenRepository;
import com.leanmate.user.repository.UserAuthIdentityEntity;
import com.leanmate.user.repository.UserAuthIdentityRepository;
import com.leanmate.user.repository.UserEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.user.repository.UserRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class AuthApplicationService {

    private static final String TOKEN_TYPE_BEARER = "Bearer";
    private static final int REFRESH_TOKEN_BYTES = 32;

    private final OAuthIdentityVerifier oAuthIdentityVerifier;
    private final UserRepository userRepository;
    private final UserAuthIdentityRepository userAuthIdentityRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final UserProfileRepository userProfileRepository;
    private final JwtTokenService jwtTokenService;
    private final JwtProperties jwtProperties;
    private final UserResponseMapper userResponseMapper;
    private final SecureRandom secureRandom = new SecureRandom();

    public AuthApplicationService(
            OAuthIdentityVerifier oAuthIdentityVerifier,
            UserRepository userRepository,
            UserAuthIdentityRepository userAuthIdentityRepository,
            RefreshTokenRepository refreshTokenRepository,
            UserProfileRepository userProfileRepository,
            JwtTokenService jwtTokenService,
            JwtProperties jwtProperties,
            UserResponseMapper userResponseMapper
    ) {
        this.oAuthIdentityVerifier = oAuthIdentityVerifier;
        this.userRepository = userRepository;
        this.userAuthIdentityRepository = userAuthIdentityRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.userProfileRepository = userProfileRepository;
        this.jwtTokenService = jwtTokenService;
        this.jwtProperties = jwtProperties;
        this.userResponseMapper = userResponseMapper;
    }

    @Transactional
    public AuthTokenResponse oauthLogin(OAuthLoginRequest request) {
        VerifiedOAuthIdentity identity = oAuthIdentityVerifier.verify(
                request.provider(),
                request.identityToken(),
                request.authorizationCode());
        UserEntity user = findOrCreateUser(identity);
        ensureActiveUser(user);
        user.setLastLoginAt(Instant.now());

        return issueTokenResponse(user, request.deviceId());
    }

    @Transactional
    public AuthTokenResponse refresh(RefreshTokenRequest request) {
        RefreshTokenEntity refreshToken = refreshTokenRepository.findByTokenHash(hashRefreshToken(request.refreshToken()))
                .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_TOKEN));

        Instant now = Instant.now();
        if (refreshToken.getRevokedAt() != null || !refreshToken.getExpiresAt().isAfter(now)) {
            if (refreshToken.getRevokedAt() == null) {
                refreshToken.setRevokedAt(now);
            }
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
        }

        UserEntity user = userRepository.findById(refreshToken.getUserId())
                .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_TOKEN));
        ensureActiveUser(user);

        refreshToken.setRevokedAt(now);
        return issueTokenResponse(user, refreshToken.getDeviceId());
    }

    @Transactional
    public void logout(UUID userId, LogoutRequest request) {
        if (request != null && StringUtils.hasText(request.refreshToken())) {
            refreshTokenRepository.findByTokenHash(hashRefreshToken(request.refreshToken()))
                    .filter(token -> token.getUserId().equals(userId))
                    .ifPresent(this::revokeToken);
            return;
        }

        refreshTokenRepository.findByUserIdAndRevokedAtIsNull(userId)
                .forEach(this::revokeToken);
    }

    private UserEntity findOrCreateUser(VerifiedOAuthIdentity identity) {
        return userAuthIdentityRepository
                .findByProviderAndProviderUserId(identity.provider().value(), identity.providerUserId())
                .map(authIdentity -> loadExistingUser(authIdentity, identity.email()))
                .orElseGet(() -> createUser(identity));
    }

    private UserEntity loadExistingUser(UserAuthIdentityEntity authIdentity, String email) {
        if (email != null && !email.equals(authIdentity.getEmail())) {
            authIdentity.setEmail(email);
        }
        return userRepository.findById(authIdentity.getUserId())
                .orElseThrow(() -> new BusinessException(ErrorCode.INTERNAL_SERVER_ERROR, "登录身份数据异常"));
    }

    private UserEntity createUser(VerifiedOAuthIdentity identity) {
        UserEntity user = new UserEntity();
        user.setStatus(UserStatus.ACTIVE.value());
        UserEntity savedUser = userRepository.save(user);

        UserAuthIdentityEntity authIdentity = new UserAuthIdentityEntity();
        authIdentity.setUserId(savedUser.getId());
        authIdentity.setProvider(identity.provider().value());
        authIdentity.setProviderUserId(identity.providerUserId());
        authIdentity.setEmail(identity.email());
        userAuthIdentityRepository.save(authIdentity);

        return savedUser;
    }

    private AuthTokenResponse issueTokenResponse(UserEntity user, String deviceId) {
        String accessToken = jwtTokenService.generateAccessToken(user.getId());
        String refreshToken = generateRefreshToken();
        saveRefreshToken(user.getId(), refreshToken, deviceId);
        boolean profileCompleted = userProfileRepository.existsByUserId(user.getId());

        return new AuthTokenResponse(
                accessToken,
                refreshToken,
                TOKEN_TYPE_BEARER,
                jwtProperties.accessTokenTtlSeconds(),
                userResponseMapper.toCurrentUserResponse(user, profileCompleted),
                profileCompleted);
    }

    private void saveRefreshToken(UUID userId, String refreshToken, String deviceId) {
        RefreshTokenEntity entity = new RefreshTokenEntity();
        entity.setUserId(userId);
        entity.setTokenHash(hashRefreshToken(refreshToken));
        entity.setDeviceId(trimToNull(deviceId));
        entity.setExpiresAt(Instant.now().plus(jwtProperties.refreshTokenTtlDays(), ChronoUnit.DAYS));
        refreshTokenRepository.save(entity);
    }

    private void revokeToken(RefreshTokenEntity refreshToken) {
        if (refreshToken.getRevokedAt() == null) {
            refreshToken.setRevokedAt(Instant.now());
        }
    }

    private void ensureActiveUser(UserEntity user) {
        if (!UserStatus.ACTIVE.value().equals(user.getStatus())) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "账号不可用");
        }
    }

    private String generateRefreshToken() {
        byte[] randomBytes = new byte[REFRESH_TOKEN_BYTES];
        secureRandom.nextBytes(randomBytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);
    }

    private String hashRefreshToken(String refreshToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(refreshToken.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 不可用", exception);
        }
    }

    private String trimToNull(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        return value.trim();
    }
}
