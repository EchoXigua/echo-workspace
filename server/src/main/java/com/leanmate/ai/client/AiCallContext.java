package com.leanmate.ai.client;

import java.util.UUID;

public record AiCallContext(
        UUID userId,
        String businessType,
        UUID businessId,
        String promptVersion,
        int attempt
) {

    public AiCallContext {
        if (attempt <= 0) {
            attempt = 1;
        }
    }
}
