package com.leanmate.ai.client;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.leanmate.ai.AiProviderProperties;
import com.leanmate.ai.dto.DietRecognitionItem;
import com.leanmate.ai.dto.DietRecognitionResult;
import com.leanmate.ai.dto.DietTextRecognitionInput;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class DeepSeekDietTextRecognitionClient {

    private static final int MAX_OUTPUT_TOKENS = 1200;

    private final AiProviderProperties properties;
    private final DeepSeekChatClient chatClient;
    private final ObjectMapper objectMapper;

    public DeepSeekDietTextRecognitionClient(
            AiProviderProperties properties,
            DeepSeekChatClient chatClient,
            ObjectMapper objectMapper
    ) {
        this.properties = properties;
        this.chatClient = chatClient;
        this.objectMapper = objectMapper;
    }

    public DietRecognitionResult recognizeText(DietTextRecognitionInput input) {
        DeepSeekChatClient.JsonCompletion completion = chatClient.completeJson(
                properties.dietTextModel(),
                List.of(
                        new DeepSeekChatClient.ChatMessage("system", systemPrompt()),
                        new DeepSeekChatClient.ChatMessage("user", userPrompt(input))),
                0.7,
                MAX_OUTPUT_TOKENS);
        Map<String, Object> parsedOutput = chatClient.parseJsonObject(completion.content());
        JsonNode root = objectMapper.valueToTree(parsedOutput);
        List<DietRecognitionItem> items = items(root.path("items"));
        return new DietRecognitionResult(
                completion.responseModel(),
                items,
                optionalText(root.path("notes")),
                rawOutput(completion, parsedOutput));
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
                - quantityText 尽量保留用户原始份量表达。
                - weightG、caloriesKcal、proteinG、fatG、carbsG 不确定时可以为 null。
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
}
