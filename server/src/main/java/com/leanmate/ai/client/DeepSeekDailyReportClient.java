package com.leanmate.ai.client;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.leanmate.ai.AiProviderProperties;
import com.leanmate.ai.dto.DailyReportInput;
import com.leanmate.ai.dto.DailyReportResult;
import com.leanmate.ai.dto.DailyReportSnapshotInput;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class DeepSeekDailyReportClient {

    private static final int MAX_OUTPUT_TOKENS = 900;

    private final AiProviderProperties properties;
    private final DeepSeekChatClient chatClient;
    private final ObjectMapper objectMapper;

    public DeepSeekDailyReportClient(
            AiProviderProperties properties,
            DeepSeekChatClient chatClient,
            ObjectMapper objectMapper
    ) {
        this.properties = properties;
        this.chatClient = chatClient;
        this.objectMapper = objectMapper;
    }

    public DailyReportResult generateDailyReport(DailyReportInput input) {
        DeepSeekChatClient.JsonCompletion completion = chatClient.completeJson(
                properties.dailyReportModel(),
                List.of(
                        new DeepSeekChatClient.ChatMessage("system", systemPrompt()),
                        new DeepSeekChatClient.ChatMessage("user", userPrompt(input))),
                0.7,
                MAX_OUTPUT_TOKENS);
        Map<String, Object> parsedOutput = chatClient.parseJsonObject(completion.content());
        return new DailyReportResult(
                completion.responseModel(),
                score(parsedOutput.get("score")),
                requiredText(parsedOutput.get("summary"), "summary"),
                requiredText(parsedOutput.get("problem"), "problem"),
                requiredText(parsedOutput.get("suggestion"), "suggestion"),
                rawOutput(completion, parsedOutput));
    }

    private String systemPrompt() {
        return """
                你是 LeanMate 的减脂饮食 AI 日报生成器。
                必须只输出一个合法 JSON 对象，不要输出 Markdown，不要输出解释。

                JSON 格式固定为：
                {
                  "score": 84,
                  "summary": "今天整体控制不错，蛋白质摄入较好。",
                  "problem": "晚餐热量偏高，剩余热量被快速用完。",
                  "suggestion": "明天早餐可以继续保证蛋白质，晚餐减少油脂和主食份量。"
                }

                规则：
                - score 是 0 到 100 的整数。
                - summary、problem、suggestion 使用简体中文。
                - 三个文本字段合计控制在 3 到 5 句话，简短、具体、可执行。
                - 只基于用户提供的结构化饮食、体重、目标和快照数据判断。
                - 不做医疗诊断，不使用恐吓式表达，不承诺减重结果。
                - 禁止提及喝水、饮水、水分、水摄入，因为当前产品没有饮水记录功能。
                - 如果记录样本少，低分主要表示记录完整度不足，不等同于用户全天吃得差。
                - 当食物记录少于 2 条时，score 通常不要高于 59；summary 必须明确“记录样本较少，判断有限”。
                - 当记录样本少且总热量远低于目标时，不要鼓励继续少吃，也不要把低热量描述为优秀控制。
                - 样本不足时，problem 优先写“餐次缺失/记录不足”，避免把“营养不均衡”说成确定结论。
                - suggestion 必须给出下一步可执行动作，例如补记正餐、下一餐增加优质蛋白或蔬菜；不要建议产品内不存在的功能。
                """;
    }

    private String userPrompt(DailyReportInput input) {
        try {
            return "请根据以下结构化数据生成 AI 日报 JSON：\n" + objectMapper.writeValueAsString(promptPayload(input));
        } catch (JsonProcessingException exception) {
            throw new AiProviderException("provider_prompt_error", "日报上下文序列化失败");
        }
    }

    private Map<String, Object> promptPayload(DailyReportInput input) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("reportDate", input.reportDate());
        payload.put("profile", input.profile());
        payload.put("goal", input.goal());
        payload.put("snapshot", input.snapshot());
        payload.put("foodEntries", input.foodEntries());
        payload.put("weightEntry", input.weightEntry());
        payload.put("streak", input.streak());
        payload.put("contextHints", contextHints(input));
        return payload;
    }

    private Map<String, Object> contextHints(DailyReportInput input) {
        DailyReportSnapshotInput snapshot = input.snapshot();
        int foodEntryCount = snapshot.foodEntryCount();
        Map<String, Object> hints = new LinkedHashMap<>();
        hints.put("foodRecordSampleLevel", foodRecordSampleLevel(foodEntryCount));
        hints.put("foodRecordCount", foodEntryCount);
        hints.put("hasWeightRecord", input.weightEntry() != null);
        hints.put("calorieCoveragePercent", calorieCoveragePercent(snapshot));
        hints.put("primaryLowScoreReason", foodEntryCount < 2 ? "food_record_sample_too_small" : "diet_goal_alignment");
        return hints;
    }

    private String foodRecordSampleLevel(int foodEntryCount) {
        if (foodEntryCount <= 1) {
            return "sparse";
        }
        if (foodEntryCount <= 2) {
            return "partial";
        }
        return "usable";
    }

    private int calorieCoveragePercent(DailyReportSnapshotInput snapshot) {
        if (snapshot.calorieTargetKcal() <= 0) {
            return 0;
        }
        return Math.max(0, Math.min(999,
                Math.round(snapshot.caloriesKcal() * 100.0F / snapshot.calorieTargetKcal())));
    }

    private int score(Object value) {
        if (value instanceof Number number) {
            return Math.max(0, Math.min(100, number.intValue()));
        }
        if (value instanceof String text && StringUtils.hasText(text)) {
            try {
                return Math.max(0, Math.min(100, Integer.parseInt(text.trim())));
            } catch (NumberFormatException exception) {
                throw new AiProviderException("provider_schema_error", "DeepSeek 日报分数字段格式错误");
            }
        }
        throw new AiProviderException("provider_schema_error", "DeepSeek 日报缺少 score");
    }

    private String requiredText(Object value, String fieldName) {
        if (value instanceof String text && StringUtils.hasText(text)) {
            return text.trim();
        }
        throw new AiProviderException("provider_schema_error", "DeepSeek 日报缺少 " + fieldName);
    }

    private Map<String, Object> rawOutput(
            DeepSeekChatClient.JsonCompletion completion,
            Map<String, Object> parsedOutput
    ) {
        Map<String, Object> rawOutput = new LinkedHashMap<>();
        rawOutput.put("provider", "deepseek");
        rawOutput.put("requestedModel", completion.requestedModel());
        rawOutput.put("model", completion.responseModel());
        rawOutput.put("mode", "daily_report");
        rawOutput.put("usage", completion.usage());
        rawOutput.put("output", parsedOutput);
        return rawOutput;
    }
}
