package com.leanmate.ai.client;

import com.leanmate.ai.AiProviderProperties;
import com.leanmate.ai.dto.DailyReportInput;
import com.leanmate.ai.dto.DailyReportResult;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;

@Component
public class PlaceholderDailyReportClient implements DailyReportClient {

    private final AiProviderProperties properties;

    public PlaceholderDailyReportClient(AiProviderProperties properties) {
        this.properties = properties;
    }

    @Override
    public DailyReportResult generateDailyReport(DailyReportInput input) {
        int caloriesKcal = input.snapshot().caloriesKcal();
        int remainingCaloriesKcal = input.snapshot().remainingCaloriesKcal();
        int foodEntryCount = input.snapshot().foodEntryCount();
        int score = score(remainingCaloriesKcal, foodEntryCount, input.weightEntry() != null);
        String summary = "今天已记录 " + foodEntryCount + " 餐，累计 " + caloriesKcal
                + " 千卡，剩余 " + remainingCaloriesKcal + " 千卡。";
        String problem = remainingCaloriesKcal < 0
                ? "当前热量已经超出目标，晚间加餐需要更克制。"
                : "目前主要问题是记录样本还少，后续判断会依赖更完整的饮食记录。";
        String suggestion = remainingCaloriesKcal < 0
                ? "明天优先保证蛋白质，减少油脂和主食份量。"
                : "下一餐继续记录食物份量，优先选择高蛋白和低油烹饪。";

        return new DailyReportResult(
                properties.dailyReportModel(),
                score,
                summary,
                problem,
                suggestion,
                rawOutput(input, score, summary, problem, suggestion));
    }

    private int score(int remainingCaloriesKcal, int foodEntryCount, boolean hasWeightEntry) {
        int score = 75;
        if (remainingCaloriesKcal >= 0) {
            score += 8;
        } else {
            score -= Math.min(20, Math.abs(remainingCaloriesKcal) / 50);
        }
        score += Math.min(6, foodEntryCount * 2);
        if (hasWeightEntry) {
            score += 2;
        }
        return Math.max(0, Math.min(100, score));
    }

    private Map<String, Object> rawOutput(
            DailyReportInput input,
            int score,
            String summary,
            String problem,
            String suggestion
    ) {
        return Map.of(
                "provider", properties.dailyReportProvider(),
                "model", properties.dailyReportModel(),
                "mode", "placeholder",
                "reportDate", input.reportDate().toString(),
                "inputs", Map.of(
                        "foodEntryCount", input.foodEntries().size(),
                        "hasWeightEntry", input.weightEntry() != null,
                        "streakDays", input.streak().currentDays()),
                "output", Map.of(
                        "score", score,
                        "summary", summary,
                        "problem", problem,
                        "suggestion", suggestion),
                "notes", List.of("AI Provider 未配置，使用结构化业务数据生成占位日报。"));
    }
}
