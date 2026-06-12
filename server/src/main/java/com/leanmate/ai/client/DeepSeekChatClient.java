package com.leanmate.ai.client;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.leanmate.ai.AiProviderProperties;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class DeepSeekChatClient {

    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
    };

    private final AiProviderProperties properties;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;

    @Autowired
    public DeepSeekChatClient(AiProviderProperties properties, ObjectMapper objectMapper) {
        this(properties, objectMapper, restClient(properties));
    }

    DeepSeekChatClient(AiProviderProperties properties, ObjectMapper objectMapper, RestClient restClient) {
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.restClient = restClient;
    }

    public JsonCompletion completeJson(
            String model,
            List<ChatMessage> messages,
            double temperature,
            int maxTokens
    ) {
        String apiKey = properties.deepseekApiKey();
        if (!StringUtils.hasText(apiKey)) {
            throw new AiProviderException("missing_api_key", "DeepSeek API Key 未配置");
        }
        String safeModel = requireText(model, "DeepSeek 模型未配置");
        Map<String, Object> requestBody = new LinkedHashMap<>();
        requestBody.put("model", safeModel);
        requestBody.put("messages", messages);
        requestBody.put("response_format", Map.of("type", "json_object"));
        requestBody.put("temperature", temperature);
        requestBody.put("max_tokens", maxTokens);
        requestBody.put("stream", false);

        JsonNode response;
        try {
            response = restClient.post()
                    .uri("/chat/completions")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + apiKey)
                    .body(requestBody)
                    .retrieve()
                    .onStatus(status -> status.isError(), (request, httpResponse) -> {
                        int httpStatus = httpResponse.getStatusCode().value();
                        throw new AiProviderException(
                                "provider_http_error",
                                "DeepSeek 服务返回错误：" + httpStatus,
                                httpStatus);
                    })
                    .body(JsonNode.class);
        } catch (AiProviderException exception) {
            throw exception;
        } catch (RestClientException exception) {
            throw new AiProviderException("provider_unavailable", "DeepSeek 服务暂时不可用");
        }

        return parseCompletion(safeModel, response);
    }

    public Map<String, Object> parseJsonObject(String content) {
        String json = extractJsonObject(content);
        try {
            return objectMapper.readValue(json, MAP_TYPE);
        } catch (Exception exception) {
            throw new AiProviderException("provider_invalid_json", "DeepSeek 返回内容不是合法 JSON");
        }
    }

    private JsonCompletion parseCompletion(String requestedModel, JsonNode response) {
        if (response == null || response.isMissingNode() || response.isNull()) {
            throw new AiProviderException("provider_empty_response", "DeepSeek 返回为空");
        }
        JsonNode choices = response.path("choices");
        if (!choices.isArray() || choices.isEmpty()) {
            throw new AiProviderException("provider_invalid_response", "DeepSeek 返回缺少 choices");
        }
        String content = choices.get(0).path("message").path("content").asText();
        if (!StringUtils.hasText(content)) {
            throw new AiProviderException("provider_empty_content", "DeepSeek 返回内容为空");
        }
        String responseModel = response.path("model").asText(requestedModel);
        Map<String, Object> usage = response.path("usage").isObject()
                ? objectMapper.convertValue(response.path("usage"), MAP_TYPE)
                : Map.of();
        return new JsonCompletion(requestedModel, responseModel, content.trim(), usage);
    }

    private String extractJsonObject(String content) {
        if (!StringUtils.hasText(content)) {
            throw new AiProviderException("provider_empty_content", "DeepSeek 返回内容为空");
        }
        String trimmed = content.trim();
        int start = trimmed.indexOf('{');
        int end = trimmed.lastIndexOf('}');
        if (start < 0 || end <= start) {
            throw new AiProviderException("provider_invalid_json", "DeepSeek 返回内容不是 JSON 对象");
        }
        return trimmed.substring(start, end + 1);
    }

    private String requireText(String value, String message) {
        if (!StringUtils.hasText(value) || "change-me".equals(value.trim())) {
            throw new AiProviderException("provider_config_error", message);
        }
        return value.trim();
    }

    private static RestClient restClient(AiProviderProperties properties) {
        Duration timeout = Duration.ofSeconds(properties.requestTimeoutSeconds());
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(timeout);
        requestFactory.setReadTimeout(timeout);
        return RestClient.builder()
                .baseUrl(trimTrailingSlash(properties.deepseekBaseUrl()))
                .requestFactory(requestFactory)
                .build();
    }

    private static String trimTrailingSlash(String value) {
        String trimmed = StringUtils.hasText(value) ? value.trim() : "https://api.deepseek.com";
        while (trimmed.endsWith("/")) {
            trimmed = trimmed.substring(0, trimmed.length() - 1);
        }
        return trimmed;
    }

    public record ChatMessage(String role, String content) {
    }

    public record JsonCompletion(
            String requestedModel,
            String responseModel,
            String content,
            Map<String, Object> usage
    ) {
    }
}
