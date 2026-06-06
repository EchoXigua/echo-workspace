package com.leanmate.user.application;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.user.domain.AuthProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class OAuthIdentityVerifier {

    private static final String MOCK_TOKEN_PREFIX = "mock:";

    private final AppleIdentityTokenVerifier appleIdentityTokenVerifier;
    private final String appEnv;

    public OAuthIdentityVerifier(
            AppleIdentityTokenVerifier appleIdentityTokenVerifier,
            @Value("${leanmate.env:local}") String appEnv
    ) {
        this.appleIdentityTokenVerifier = appleIdentityTokenVerifier;
        this.appEnv = appEnv;
    }

    public VerifiedOAuthIdentity verify(AuthProvider provider, String identityToken, String authorizationCode) {
        if (provider == AuthProvider.GOOGLE) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "V1.1 暂不支持 Google 登录");
        }
        if (provider != AuthProvider.APPLE) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "不支持的登录方式");
        }
        if (isMockEnvironment() && identityToken.startsWith(MOCK_TOKEN_PREFIX)) {
            return verifyMockAppleIdentity(identityToken);
        }
        return appleIdentityTokenVerifier.verify(identityToken);
    }

    private boolean isMockEnvironment() {
        return "local".equalsIgnoreCase(appEnv) || "test".equalsIgnoreCase(appEnv);
    }

    private VerifiedOAuthIdentity verifyMockAppleIdentity(String identityToken) {
        String payload = identityToken.substring(MOCK_TOKEN_PREFIX.length());
        String[] parts = payload.split(":", -1);
        String providerUserId = parts.length > 0 ? parts[0] : "";
        String email = parts.length > 1 ? parts[1] : null;

        if (!StringUtils.hasText(providerUserId) || providerUserId.length() > 128) {
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
        }
        if (email != null && email.length() > 255) {
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
        }
        return new VerifiedOAuthIdentity(AuthProvider.APPLE, providerUserId, email);
    }
}
