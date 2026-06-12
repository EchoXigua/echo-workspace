package com.leanmate.ai.client;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.leanmate.ai.AiProviderProperties;
import com.leanmate.ai.application.AiModelCallLogService;
import com.leanmate.ai.application.AiModelCallLogService.AiModelCallLogCommand;
import com.leanmate.ai.dto.DailyReportFoodEntryInput;
import com.leanmate.ai.dto.DailyReportFoodItemInput;
import com.leanmate.ai.dto.DailyReportGoalInput;
import com.leanmate.ai.dto.DailyReportInput;
import com.leanmate.ai.dto.DailyReportProfileInput;
import com.leanmate.ai.dto.DailyReportResult;
import com.leanmate.ai.dto.DailyReportSnapshotInput;
import com.leanmate.ai.dto.DailyReportStreakInput;
import com.leanmate.ai.dto.DailyReportWeightEntryInput;
import com.leanmate.ai.dto.DietPhotoRecognitionInput;
import com.leanmate.ai.dto.DietRecognitionResult;
import com.leanmate.ai.dto.DietTextRecognitionInput;
import com.leanmate.common.web.RequestContext;
import com.leanmate.diet.domain.MealType;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class DeepSeekAiClientTests {

    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Test
    void chatClientPostsJsonRequestAndReturnsContent() {
        RestClient.Builder builder = RestClient.builder().baseUrl("https://api.deepseek.com");
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        DeepSeekChatClient client = new DeepSeekChatClient(properties(), objectMapper, builder.build());
        server.expect(requestTo("https://api.deepseek.com/chat/completions"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header(HttpHeaders.AUTHORIZATION, "Bearer test-key"))
                .andRespond(withSuccess("""
                        {
                          "model": "deepseek-v4-flash",
                          "choices": [
                            {
                              "message": {
                                "content": "{\\"score\\":88}"
                              }
                            }
                          ],
                          "usage": {
                            "total_tokens": 20
                          }
                        }
                        """, MediaType.APPLICATION_JSON));

        DeepSeekChatClient.JsonCompletion completion = client.completeJson(
                "deepseek-v4-flash",
                List.of(new DeepSeekChatClient.ChatMessage("user", "输出 JSON")),
                0.7,
                256);

        assertThat(completion.content()).isEqualTo("{\"score\":88}");
        assertThat(completion.usage()).containsEntry("total_tokens", 20);
        assertThat(client.parseJsonObject(completion.content())).containsEntry("score", 88);
        server.verify();
    }

    @Test
    void dailyReportClientRecordsSuccessfulAiCall() {
        DeepSeekChatClient chatClient = mock(DeepSeekChatClient.class);
        AiModelCallLogService callLogService = mock(AiModelCallLogService.class);
        UUID reportId = UUID.randomUUID();
        DeepSeekChatClient.JsonCompletion completion = new DeepSeekChatClient.JsonCompletion(
                "deepseek-v4-flash",
                "deepseek-v4-flash",
                "{}",
                Map.of("prompt_tokens", 10, "completion_tokens", 5, "total_tokens", 15));
        when(chatClient.completeJson(anyString(), anyList(), anyDouble(), anyInt())).thenReturn(completion);
        when(chatClient.parseJsonObject("{}")).thenReturn(Map.of(
                "score", 91,
                "summary", "今天整体控制不错。",
                "problem", "晚餐热量略高。",
                "suggestion", "明天晚餐减少油脂。"));
        RequestContext.setRequestId("test-request-123");

        try {
            new DeepSeekDailyReportClient(properties(), chatClient, objectMapper, callLogService)
                    .generateDailyReport(dailyReportInput(), reportId);
        } finally {
            RequestContext.clear();
        }

        ArgumentCaptor<AiModelCallLogCommand> commandCaptor = ArgumentCaptor.forClass(AiModelCallLogCommand.class);
        verify(callLogService).record(commandCaptor.capture());
        AiModelCallLogCommand command = commandCaptor.getValue();
        assertThat(command.requestId()).isEqualTo("test-request-123");
        assertThat(command.userId()).isNotNull();
        assertThat(command.businessType()).isEqualTo("daily_report");
        assertThat(command.businessId()).isEqualTo(reportId);
        assertThat(command.status()).isEqualTo("succeeded");
        assertThat(command.promptTokens()).isEqualTo(10);
        assertThat(command.completionTokens()).isEqualTo(5);
        assertThat(command.totalTokens()).isEqualTo(15);
    }

    @Test
    void chatClientRejectsMissingApiKey() {
        DeepSeekChatClient client = new DeepSeekChatClient(
                propertiesWithProviders("deepseek", "deepseek", ""),
                objectMapper,
                RestClient.builder().baseUrl("https://api.deepseek.com").build());

        assertThatThrownBy(() -> client.completeJson(
                "deepseek-v4-flash",
                List.of(new DeepSeekChatClient.ChatMessage("user", "输出 JSON")),
                0.7,
                256))
                .isInstanceOf(AiProviderException.class)
                .extracting("providerErrorCode")
                .isEqualTo("missing_api_key");
    }

    @Test
    void dailyReportClientParsesStructuredOutput() {
        DeepSeekChatClient chatClient = mock(DeepSeekChatClient.class);
        DeepSeekChatClient.JsonCompletion completion = new DeepSeekChatClient.JsonCompletion(
                "deepseek-v4-flash",
                "deepseek-v4-flash",
                "{}",
                Map.of("total_tokens", 120));
        when(chatClient.completeJson(anyString(), anyList(), anyDouble(), anyInt())).thenReturn(completion);
        when(chatClient.parseJsonObject("{}")).thenReturn(Map.of(
                "score", 91,
                "summary", "今天整体控制不错。",
                "problem", "晚餐热量略高。",
                "suggestion", "明天晚餐减少油脂。"));

        DailyReportResult result = new DeepSeekDailyReportClient(properties(), chatClient, objectMapper)
                .generateDailyReport(dailyReportInput());
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<DeepSeekChatClient.ChatMessage>> messagesCaptor = ArgumentCaptor.forClass(List.class);
        verify(chatClient).completeJson(anyString(), messagesCaptor.capture(), anyDouble(), anyInt());
        List<DeepSeekChatClient.ChatMessage> messages = messagesCaptor.getValue();

        assertThat(result.modelName()).isEqualTo("deepseek-v4-flash");
        assertThat(result.score()).isEqualTo(91);
        assertThat(result.summary()).isEqualTo("今天整体控制不错。");
        assertThat(result.rawOutput()).containsEntry("provider", "deepseek");
        assertThat(messages.get(0).content())
                .contains("禁止提及喝水、饮水、水分、水摄入")
                .contains("记录样本少且总热量远低于目标");
        assertThat(messages.get(1).content())
                .contains("\"contextHints\"")
                .contains("\"foodRecordSampleLevel\":\"partial\"");
    }

    @Test
    void dietTextClientParsesStructuredItems() {
        DeepSeekChatClient chatClient = mock(DeepSeekChatClient.class);
        DeepSeekChatClient.JsonCompletion completion = new DeepSeekChatClient.JsonCompletion(
                "deepseek-v4-flash",
                "deepseek-v4-flash",
                "{}",
                Map.of());
        when(chatClient.completeJson(anyString(), anyList(), anyDouble(), anyInt())).thenReturn(completion);
        when(chatClient.parseJsonObject("{}")).thenReturn(Map.of(
                "items", List.of(Map.of(
                        "name", "鸡蛋",
                        "quantityText", "2个",
                        "weightG", 100,
                        "caloriesKcal", 140,
                        "proteinG", 12.0,
                        "fatG", 10.0,
                        "carbsG", 1.0,
                        "confidence", 0.82)),
                "notes", "按常见鸡蛋估算。"));

        DietRecognitionResult result = new DeepSeekDietTextRecognitionClient(properties(), chatClient, objectMapper)
                .recognizeText(new DietTextRecognitionInput(
                        UUID.randomUUID(),
                        UUID.randomUUID(),
                        LocalDate.parse("2026-06-08"),
                        MealType.BREAKFAST,
                        "早餐吃了两个鸡蛋"));

        assertThat(result.modelName()).isEqualTo("deepseek-v4-flash");
        assertThat(result.items()).hasSize(1);
        assertThat(result.items().get(0).name()).isEqualTo("鸡蛋");
        assertThat(result.items().get(0).caloriesKcal()).isEqualTo(140);
        assertThat(result.notes()).isEqualTo("按常见鸡蛋估算。");

        ArgumentCaptor<List<DeepSeekChatClient.ChatMessage>> messagesCaptor = ArgumentCaptor.forClass(List.class);
        verify(chatClient).completeJson(anyString(), messagesCaptor.capture(), eq(0.2), anyInt());
        assertThat(messagesCaptor.getValue().get(0).content())
                .contains("不要把整句话、餐次、份量、括号说明放进 name")
                .contains("必须拆成多个 items")
                .contains("常见食物且用户给出份量时，必须估算");
    }

    @Test
    void routingDietClientKeepsPhotoPlaceholderAndRoutesTextToDeepSeek() {
        PlaceholderDietRecognitionClient placeholderClient = mock(PlaceholderDietRecognitionClient.class);
        DeepSeekDietTextRecognitionClient deepSeekClient = mock(DeepSeekDietTextRecognitionClient.class);
        RoutingDietRecognitionClient routingClient = new RoutingDietRecognitionClient(
                propertiesWithProviders("deepseek", "deepseek", "test-key"),
                placeholderClient,
                deepSeekClient);
        DietPhotoRecognitionInput photoInput = new DietPhotoRecognitionInput(
                UUID.randomUUID(),
                UUID.randomUUID(),
                LocalDate.parse("2026-06-08"),
                MealType.LUNCH,
                null,
                "object-key",
                "image/jpeg",
                1024);
        DietTextRecognitionInput textInput = new DietTextRecognitionInput(
                UUID.randomUUID(),
                UUID.randomUUID(),
                LocalDate.parse("2026-06-08"),
                MealType.LUNCH,
                "一碗米饭");

        routingClient.recognizePhoto(photoInput);
        routingClient.recognizeText(textInput);

        verify(placeholderClient).recognizePhoto(photoInput);
        verify(deepSeekClient).recognizeText(textInput);
    }

    @Test
    void routingDailyReportClientRoutesToDeepSeek() {
        PlaceholderDailyReportClient placeholderClient = mock(PlaceholderDailyReportClient.class);
        DeepSeekDailyReportClient deepSeekClient = mock(DeepSeekDailyReportClient.class);
        RoutingDailyReportClient routingClient = new RoutingDailyReportClient(
                propertiesWithProviders("deepseek", "deepseek", "test-key"),
                placeholderClient,
                deepSeekClient);
        DailyReportInput input = dailyReportInput();

        routingClient.generateDailyReport(input);

        verify(deepSeekClient).generateDailyReport(input);
        verifyNoInteractions(placeholderClient);
    }

    private DailyReportInput dailyReportInput() {
        LocalDate date = LocalDate.parse("2026-06-08");
        return new DailyReportInput(
                UUID.randomUUID(),
                date,
                new DailyReportProfileInput(
                        "female",
                        30,
                        new BigDecimal("165"),
                        new BigDecimal("59.5"),
                        new BigDecimal("55"),
                        "light",
                        1520),
                new DailyReportGoalInput(
                        new BigDecimal("62"),
                        new BigDecimal("55"),
                        LocalDate.parse("2026-09-01"),
                        1520),
                new DailyReportSnapshotInput(
                        date,
                        1520,
                        1280,
                        240,
                        new BigDecimal("72"),
                        new BigDecimal("42"),
                        new BigDecimal("138"),
                        2,
                        new BigDecimal("59.5")),
                List.of(new DailyReportFoodEntryInput(
                        date,
                        MealType.LUNCH.value(),
                        520,
                        List.of(new DailyReportFoodItemInput(
                                "鸡胸肉",
                                "一份",
                                new BigDecimal("150"),
                                240,
                                new BigDecimal("35"),
                                new BigDecimal("5"),
                                new BigDecimal("2"))))),
                new DailyReportWeightEntryInput(date, new BigDecimal("59.5")),
                new DailyReportStreakInput(3, 7, date));
    }

    private AiProviderProperties properties() {
        return propertiesWithProviders("deepseek", "deepseek", "test-key");
    }

    private AiProviderProperties propertiesWithProviders(
            String dietTextProvider,
            String dailyReportProvider,
            String deepseekApiKey
    ) {
        return new AiProviderProperties(
                "placeholder",
                "",
                "",
                "placeholder",
                dietTextProvider,
                dailyReportProvider,
                "placeholder-diet-photo",
                "deepseek-v4-flash",
                "deepseek-v4-flash",
                deepseekApiKey,
                "https://api.deepseek.com",
                30,
                1);
    }
}
