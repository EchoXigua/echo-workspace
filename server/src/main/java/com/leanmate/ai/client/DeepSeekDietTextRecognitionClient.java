package com.leanmate.ai.client;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.leanmate.ai.AiProviderProperties;
import com.leanmate.ai.application.AiModelCallLogService;
import com.leanmate.ai.application.AiModelCallLogService.AiModelCallLogCommand;
import com.leanmate.common.web.RequestContext;
import com.leanmate.ai.dto.DietRecognitionItem;
import com.leanmate.ai.dto.DietRecognitionResult;
import com.leanmate.ai.dto.DietTextRecognitionInput;
import java.time.Instant;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class DeepSeekDietTextRecognitionClient {

    private static final int MAX_OUTPUT_TOKENS = 1200;

    private final AiProviderProperties properties;
    private final DeepSeekChatClient chatClient;
    private final ObjectMapper objectMapper;
    private final AiModelCallLogService aiModelCallLogService;

    @Autowired
    public DeepSeekDietTextRecognitionClient(
            AiProviderProperties properties,
            DeepSeekChatClient chatClient,
            ObjectMapper objectMapper,
            AiModelCallLogService aiModelCallLogService
    ) {
        this.properties = properties;
        this.chatClient = chatClient;
        this.objectMapper = objectMapper;
        this.aiModelCallLogService = aiModelCallLogService;
    }

    DeepSeekDietTextRecognitionClient(
            AiProviderProperties properties,
            DeepSeekChatClient chatClient,
            ObjectMapper objectMapper
    ) {
        this(properties, chatClient, objectMapper, null);
    }

    public DietRecognitionResult recognizeText(DietTextRecognitionInput input) {
        AiCallContext context = new AiCallContext(
                input.userId(),
                "diet_text_recognition",
                input.taskId(),
                "diet-text-recognition:v1",
                1);
        long startedAt = System.nanoTime();
        DeepSeekChatClient.JsonCompletion completion = null;
        try {
            completion = chatClient.completeJson(
                    properties.dietTextModel(),
                    List.of(
                            new DeepSeekChatClient.ChatMessage("system", systemPrompt()),
                            new DeepSeekChatClient.ChatMessage("user", userPrompt(input))),
                    0.2,
                    MAX_OUTPUT_TOKENS);
            Map<String, Object> parsedOutput = chatClient.parseJsonObject(completion.content());
            JsonNode root = objectMapper.valueToTree(parsedOutput);
            List<DietRecognitionItem> items = items(root.path("items"));
            recordSuccess(context, completion, startedAt);
            return new DietRecognitionResult(
                    completion.responseModel(),
                    items,
                    optionalText(root.path("notes")),
                    rawOutput(completion, parsedOutput));
        } catch (AiProviderException exception) {
            recordFailure(context, completion, exception, startedAt);
            throw exception;
        }
    }

    private String systemPrompt() {
        return """
                你是 LeanMate 的饮食文本解析器。
                必须只输出一个合法 JSON 对象，不要输出 Markdown，不要输出解释。

                JSON 格式固定为：
                {
                  "items": [
                    {
                      "name": "鸡蛋",
                      "quantityText": "2个",
                      "weightG": 100,
                      "caloriesKcal": 140,
                      "proteinG": 12.0,
                      "fatG": 10.0,
                      "carbsG": 1.0,
                      "confidence": 0.82
                    }
                  ],
                  "notes": "份量不确定时已按常见食物估算。"
                }

                规则：
                - name 必填，使用简体中文食物名。
                - name 只写食物本身，例如“米饭”“鸡蛋”“豆浆”，不要把整句话、餐次、份量、括号说明放进 name。
                - 用户输入里出现多个食物时，必须拆成多个 items；逗号、顿号、分号、换行、“和”通常表示多个食物。
                - 示例：“一碗米饭（约180g），一个鸡蛋（约55g），一杯豆浆（约250ml）”必须输出 3 个 items：米饭、鸡蛋、豆浆。
                - quantityText 只保留数量/份量表达，例如“2个”“一杯”“一碗”，不要包含“约55g”“约250ml”等重量或容量说明。
                - 常见食物且用户给出份量时，必须估算 weightG、caloriesKcal、proteinG、fatG、carbsG，不要留空。
                - ml 可按近似克重估算，尤其是豆浆、牛奶、咖啡等饮品。
                - 只有完全无法判断食物或份量时，weightG、caloriesKcal、proteinG、fatG、carbsG 才可以为 null。
                - confidence 是 0 到 1 的数字。
                - 不要把用户没提到的食物补进去。
                - 估算只是候选值，用户后续会确认和修改。
                """;
    }

    private String userPrompt(DietTextRecognitionInput input) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("mealDate", input.mealDate());
        payload.put("mealType", input.mealType());
        payload.put("text", input.text());
        try {
            return "请解析以下饮食文本并输出 JSON：\n" + objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException exception) {
            throw new AiProviderException("provider_prompt_error", "饮食文本上下文序列化失败");
        }
    }

    private List<DietRecognitionItem> items(JsonNode itemsNode) {
        if (!itemsNode.isArray() || itemsNode.isEmpty()) {
            throw new AiProviderException("provider_schema_error", "DeepSeek 饮食解析缺少 items");
        }
        List<DietRecognitionItem> items = new ArrayList<>();
        for (JsonNode itemNode : itemsNode) {
            items.add(new DietRecognitionItem(
                    requiredText(itemNode.path("name"), "name"),
                    optionalText(itemNode.path("quantityText")),
                    decimal(itemNode.path("weightG"), "weightG"),
                    integer(itemNode.path("caloriesKcal"), "caloriesKcal"),
                    decimal(itemNode.path("proteinG"), "proteinG"),
                    decimal(itemNode.path("fatG"), "fatG"),
                    decimal(itemNode.path("carbsG"), "carbsG"),
                    confidence(itemNode.path("confidence"))));
        }
        return items;
    }

    private String requiredText(JsonNode node, String fieldName) {
        String text = optionalText(node);
        if (StringUtils.hasText(text)) {
            return text;
        }
        throw new AiProviderException("provider_schema_error", "DeepSeek 饮食解析缺少 " + fieldName);
    }

    private String optionalText(JsonNode node) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        String text = node.asText();
        return StringUtils.hasText(text) ? text.trim() : null;
    }

    private Integer integer(JsonNode node, String fieldName) {
        if (isEmpty(node)) {
            return null;
        }
        try {
            return node.isNumber() ? node.intValue() : Integer.parseInt(node.asText().trim());
        } catch (NumberFormatException exception) {
            throw new AiProviderException("provider_schema_error", "DeepSeek 饮食解析字段格式错误：" + fieldName);
        }
    }

    private BigDecimal decimal(JsonNode node, String fieldName) {
        if (isEmpty(node)) {
            return null;
        }
        try {
            return new BigDecimal(node.asText().trim());
        } catch (NumberFormatException exception) {
            throw new AiProviderException("provider_schema_error", "DeepSeek 饮食解析字段格式错误：" + fieldName);
        }
    }

    private BigDecimal confidence(JsonNode node) {
        BigDecimal value = decimal(node, "confidence");
        if (value == null) {
            return null;
        }
        if (value.compareTo(BigDecimal.ZERO) < 0) {
            return BigDecimal.ZERO;
        }
        if (value.compareTo(BigDecimal.ONE) > 0) {
            return BigDecimal.ONE;
        }
        return value;
    }

    private boolean isEmpty(JsonNode node) {
        return node == null
                || node.isMissingNode()
                || node.isNull()
                || (node.isTextual() && !StringUtils.hasText(node.asText()));
    }

    private Map<String, Object> rawOutput(
            DeepSeekChatClient.JsonCompletion completion,
            Map<String, Object> parsedOutput
    ) {
        Map<String, Object> rawOutput = new LinkedHashMap<>();
        rawOutput.put("provider", "deepseek");
        rawOutput.put("requestedModel", completion.requestedModel());
        rawOutput.put("model", completion.responseModel());
        rawOutput.put("mode", "diet_text_recognition");
        rawOutput.put("usage", completion.usage());
        rawOutput.put("output", parsedOutput);
        return rawOutput;
    }

    private void recordSuccess(
            AiCallContext context,
            DeepSeekChatClient.JsonCompletion completion,
            long startedAt
    ) {
        if (aiModelCallLogService == null) {
            return;
        }
        aiModelCallLogService.record(new AiModelCallLogCommand(
                RequestContext.getOrCreateRequestId(),
                context.userId(),
                context.businessType(),
                context.businessId(),
                "deepseek",
                completion.requestedModel(),
                completion.responseModel(),
                context.promptVersion(),
                "succeeded",
                200,
                null,
                null,
                token(completion.usage(), "prompt_tokens"),
                token(completion.usage(), "completion_tokens"),
                token(completion.usage(), "total_tokens"),
                null,
                durationMs(startedAt),
                context.attempt(),
                Instant.now()));
    }

    private void recordFailure(
            AiCallContext context,
            DeepSeekChatClient.JsonCompletion completion,
            AiProviderException exception,
            long startedAt
    ) {
        if (aiModelCallLogService == null) {
            return;
        }
        aiModelCallLogService.record(new AiModelCallLogCommand(
                RequestContext.getOrCreateRequestId(),
                context.userId(),
                context.businessType(),
                context.businessId(),
                "deepseek",
                completion == null ? properties.dietTextModel() : completion.requestedModel(),
                completion == null ? null : completion.responseModel(),
                context.promptVersion(),
                status(exception.providerErrorCode()),
                exception.providerHttpStatus() == null && completion != null ? 200 : exception.providerHttpStatus(),
                exception.providerErrorCode(),
                safeErrorMessage(exception.getMessage()),
                completion == null ? null : token(completion.usage(), "prompt_tokens"),
                completion == null ? null : token(completion.usage(), "completion_tokens"),
                completion == null ? null : token(completion.usage(), "total_tokens"),
                null,
                durationMs(startedAt),
                context.attempt(),
                Instant.now()));
    }

    private Integer token(Map<String, Object> usage, String key) {
        Object value = usage.get(key);
        if (value instanceof Number number) {
            return number.intValue();
        }
        if (value instanceof String stringValue && StringUtils.hasText(stringValue)) {
            try {
                return Integer.parseInt(stringValue.trim());
            } catch (NumberFormatException exception) {
                return null;
            }
        }
        return null;
    }

    private String status(String providerErrorCode) {
        if (providerErrorCode != null && (providerErrorCode.contains("invalid")
                || providerErrorCode.contains("empty")
                || providerErrorCode.contains("schema"))) {
            return "invalid_response";
        }
        return "failed";
    }

    private long durationMs(long startedAt) {
        return (System.nanoTime() - startedAt) / 1_000_000L;
    }

    private String safeErrorMessage(String message) {
        if (!StringUtils.hasText(message)) {
            return null;
        }
        String trimmed = message.trim();
        if (trimmed.length() > 500) {
            return trimmed.substring(0, 500);
        }
        return trimmed;
    }
}
