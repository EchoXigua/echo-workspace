package com.leanmate.ai.dto;

import java.util.List;
import java.util.Map;

public record DietRecognitionResult(
        String modelName,
        List<DietRecognitionItem> items,
        String notes,
        Map<String, Object> rawOutput
) {
}
