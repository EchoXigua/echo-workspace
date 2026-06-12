package com.leanmate.ai.client;

import com.leanmate.ai.AiProviderProperties;
import com.leanmate.ai.dto.DailyReportInput;
import com.leanmate.ai.dto.DailyReportResult;
import java.util.UUID;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

@Primary
@Component
public class RoutingDailyReportClient implements DailyReportClient {

    private final AiProviderProperties properties;
    private final PlaceholderDailyReportClient placeholderDailyReportClient;
    private final DeepSeekDailyReportClient deepSeekDailyReportClient;

    public RoutingDailyReportClient(
            AiProviderProperties properties,
            PlaceholderDailyReportClient placeholderDailyReportClient,
            DeepSeekDailyReportClient deepSeekDailyReportClient
    ) {
        this.properties = properties;
        this.placeholderDailyReportClient = placeholderDailyReportClient;
        this.deepSeekDailyReportClient = deepSeekDailyReportClient;
    }

    @Override
    public DailyReportResult generateDailyReport(DailyReportInput input) {
        String provider = properties.dailyReportProvider();
        if ("deepseek".equalsIgnoreCase(provider)) {
            return deepSeekDailyReportClient.generateDailyReport(input);
        }
        if ("placeholder".equalsIgnoreCase(provider)) {
            return placeholderDailyReportClient.generateDailyReport(input);
        }
        throw new AiProviderException("provider_unsupported", "AI 日报 Provider 暂不支持：" + provider);
    }

    @Override
    public DailyReportResult generateDailyReport(DailyReportInput input, UUID reportId) {
        String provider = properties.dailyReportProvider();
        if ("deepseek".equalsIgnoreCase(provider)) {
            return deepSeekDailyReportClient.generateDailyReport(input, reportId);
        }
        if ("placeholder".equalsIgnoreCase(provider)) {
            return placeholderDailyReportClient.generateDailyReport(input);
        }
        throw new AiProviderException("provider_unsupported", "AI 日报 Provider 暂不支持：" + provider);
    }
}
