package com.leanmate.user.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.user.domain.AuthProvider;
import org.junit.jupiter.api.Test;

class OAuthIdentityVerifierTests {

    private final AppleIdentityTokenVerifier appleIdentityTokenVerifier = mock(AppleIdentityTokenVerifier.class);

    @Test
    void allowControlledMockVerifierInTestEnvironment() {
        OAuthIdentityVerifier verifier = new OAuthIdentityVerifier(appleIdentityTokenVerifier, "test");

        VerifiedOAuthIdentity identity = verifier.verify(AuthProvider.APPLE, "mock:apple-user-1:user@example.com", null);

        assertThat(identity.provider()).isEqualTo(AuthProvider.APPLE);
        assertThat(identity.providerUserId()).isEqualTo("apple-user-1");
        assertThat(identity.email()).isEqualTo("user@example.com");
    }

    @Test
    void rejectGoogleProviderInV11() {
        OAuthIdentityVerifier verifier = new OAuthIdentityVerifier(appleIdentityTokenVerifier, "test");

        assertThatThrownBy(() -> verifier.verify(AuthProvider.GOOGLE, "mock:google-user-1", null))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.BAD_REQUEST);
    }
}
