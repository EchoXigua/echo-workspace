package com.leanmate.common.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "leanmate.limits")
public record LimitProperties(
        int maxUploadImageSizeMb,
        int dailyAiRecognitionLimit,
        int dailyReportGenerateLimit
) {

    public LimitProperties {
        if (maxUploadImageSizeMb <= 0) {
            maxUploadImageSizeMb = 8;
        }
        if (dailyAiRecognitionLimit <= 0) {
            dailyAiRecognitionLimit = 30;
        }
        if (dailyReportGenerateLimit <= 0) {
            dailyReportGenerateLimit = 3;
        }
    }

    public long maxUploadImageSizeBytes() {
        return maxUploadImageSizeMb * 1024L * 1024L;
    }
}
