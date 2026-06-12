package com.leanmate.common.web;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "leanmate.observability")
public record ObservabilityProperties(
        boolean accessLogEnabled,
        boolean accessLogIncludeQueryKeys,
        long accessLogSlowThresholdMs,
        boolean aiCallLogEnabled,
        boolean aiCallLogSaveDebugPayload
) {

    public ObservabilityProperties {
        if (accessLogSlowThresholdMs <= 0) {
            accessLogSlowThresholdMs = 1000;
        }
    }
}
