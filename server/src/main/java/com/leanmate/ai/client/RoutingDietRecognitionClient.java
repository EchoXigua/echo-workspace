package com.leanmate.ai.client;

import com.leanmate.ai.AiProviderProperties;
import com.leanmate.ai.dto.DietPhotoRecognitionInput;
import com.leanmate.ai.dto.DietRecognitionResult;
import com.leanmate.ai.dto.DietTextRecognitionInput;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

@Primary
@Component
public class RoutingDietRecognitionClient implements DietRecognitionClient {

    private final AiProviderProperties properties;
    private final PlaceholderDietRecognitionClient placeholderDietRecognitionClient;
    private final DeepSeekDietTextRecognitionClient deepSeekDietTextRecognitionClient;

    public RoutingDietRecognitionClient(
            AiProviderProperties properties,
            PlaceholderDietRecognitionClient placeholderDietRecognitionClient,
            DeepSeekDietTextRecognitionClient deepSeekDietTextRecognitionClient
    ) {
        this.properties = properties;
        this.placeholderDietRecognitionClient = placeholderDietRecognitionClient;
        this.deepSeekDietTextRecognitionClient = deepSeekDietTextRecognitionClient;
    }

    @Override
    public DietRecognitionResult recognizePhoto(DietPhotoRecognitionInput input) {
        String provider = properties.dietPhotoProvider();
        if ("placeholder".equalsIgnoreCase(provider)) {
            return placeholderDietRecognitionClient.recognizePhoto(input);
        }
        throw new AiProviderException("provider_unsupported", "拍照识别 Provider 暂不支持：" + provider);
    }

    @Override
    public DietRecognitionResult recognizeText(DietTextRecognitionInput input) {
        String provider = properties.dietTextProvider();
        if ("deepseek".equalsIgnoreCase(provider)) {
            return deepSeekDietTextRecognitionClient.recognizeText(input);
        }
        if ("placeholder".equalsIgnoreCase(provider)) {
            return placeholderDietRecognitionClient.recognizeText(input);
        }
        throw new AiProviderException("provider_unsupported", "文本饮食识别 Provider 暂不支持：" + provider);
    }
}
