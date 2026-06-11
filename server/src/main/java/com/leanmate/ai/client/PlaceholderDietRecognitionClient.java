package com.leanmate.ai.client;

import com.leanmate.ai.AiProviderProperties;
import com.leanmate.ai.dto.DietPhotoRecognitionInput;
import com.leanmate.ai.dto.DietRecognitionItem;
import com.leanmate.ai.dto.DietRecognitionResult;
import com.leanmate.ai.dto.DietTextRecognitionInput;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class PlaceholderDietRecognitionClient implements DietRecognitionClient {

    private static final String PLACEHOLDER_NOTE = "AI Provider 未配置，返回待用户确认的占位候选项。";

    private final AiProviderProperties properties;

    public PlaceholderDietRecognitionClient(AiProviderProperties properties) {
        this.properties = properties;
    }

    @Override
    public DietRecognitionResult recognizePhoto(DietPhotoRecognitionInput input) {
        DietRecognitionItem item = new DietRecognitionItem(
                "拍照饮食待确认",
                null,
                null,
                null,
                null,
                null,
                null,
                new BigDecimal("0.20"));
        return new DietRecognitionResult(
                properties.dietPhotoModel(),
                List.of(item),
                PLACEHOLDER_NOTE,
                rawOutput("photo", properties.dietPhotoProvider(), properties.dietPhotoModel(), input.objectKey()));
    }

    @Override
    public DietRecognitionResult recognizeText(DietTextRecognitionInput input) {
        DietRecognitionItem item = new DietRecognitionItem(
                itemName(input.text()),
                null,
                null,
                null,
                null,
                null,
                null,
                new BigDecimal("0.30"));
        return new DietRecognitionResult(
                properties.dietTextModel(),
                List.of(item),
                PLACEHOLDER_NOTE,
                rawOutput("text", properties.dietTextProvider(), properties.dietTextModel(), "text"));
    }

    private Map<String, Object> rawOutput(String sourceType, String provider, String modelName, String inputRef) {
        return Map.of(
                "provider", provider,
                "model", modelName,
                "sourceType", sourceType,
                "inputRef", inputRef,
                "mode", "placeholder",
                "notes", PLACEHOLDER_NOTE);
    }

    private String itemName(String text) {
        String normalized = StringUtils.hasText(text) ? text.trim().replaceAll("\\s+", " ") : "文本饮食待确认";
        if (normalized.length() <= 32) {
            return normalized;
        }
        return normalized.substring(0, 32);
    }
}
