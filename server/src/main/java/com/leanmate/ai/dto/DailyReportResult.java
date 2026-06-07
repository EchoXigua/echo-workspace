package com.leanmate.ai.dto;

import java.util.Map;

public record DailyReportResult(
        String modelName,
        int score,
        String summary,
        String problem,
        String suggestion,
        Map<String, Object> rawOutput
) {
}
