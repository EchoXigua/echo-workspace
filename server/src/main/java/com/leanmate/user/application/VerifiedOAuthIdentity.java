package com.leanmate.user.application;

import com.leanmate.user.domain.AuthProvider;

public record VerifiedOAuthIdentity(
        AuthProvider provider,
        String providerUserId,
        String email
) {
}
