package com.leanmate.user.application;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "leanmate.apple")
public record AppleAuthProperties(
        String clientId,
        String teamId,
        String keyId,
        String privateKey
) {
}
