package com.leanmate.common.security;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "leanmate.cors")
public record CorsProperties(
        List<String> allowedOriginPatterns,
        List<String> allowedMethods,
        List<String> allowedHeaders,
        boolean allowCredentials,
        long maxAgeSeconds
) {

    public CorsProperties {
        allowedOriginPatterns = normalize(allowedOriginPatterns, List.of("*"));
        allowedMethods = normalize(allowedMethods, List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        allowedHeaders = normalize(allowedHeaders, List.of("Authorization", "Content-Type", "Accept", "Origin"));
        if (maxAgeSeconds <= 0) {
            maxAgeSeconds = 3600;
        }
    }

    private static List<String> normalize(List<String> values, List<String> fallback) {
        if (values == null || values.isEmpty()) {
            return fallback;
        }
        List<String> normalized = values.stream()
                .filter(value -> value != null && !value.isBlank())
                .map(String::trim)
                .toList();
        return normalized.isEmpty() ? fallback : normalized;
    }
}
