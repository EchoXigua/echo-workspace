package com.leanmate.ai;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "leanmate.ai")
public record AiProviderProperties(
        String provider,
        String apiKey,
        String baseUrl,
        String dietPhotoModel,
        String dietTextModel,
        String dailyReportModel,
        int requestTimeoutSeconds,
        int dailyReportRetryLimit
) {

    public AiProviderProperties {
        provider = defaultIfBlank(provider, "placeholder");
        baseUrl = defaultIfBlank(baseUrl, "");
        dietPhotoModel = defaultIfBlank(dietPhotoModel, "placeholder-diet-photo");
        dietTextModel = defaultIfBlank(dietTextModel, "placeholder-diet-text");
        dailyReportModel = defaultIfBlank(dailyReportModel, "placeholder-daily-report");
        if (requestTimeoutSeconds <= 0) {
            requestTimeoutSeconds = 30;
        }
        if (dailyReportRetryLimit < 0) {
            dailyReportRetryLimit = 1;
        }
    }

    private static String defaultIfBlank(String value, String fallback) {
        if (value == null || value.isBlank()) {
            return fallback;
        }
        return value.trim();
    }
}
