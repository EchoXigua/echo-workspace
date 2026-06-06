package com.leanmate.diet.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.leanmate.ai.client.AiProviderException;
import com.leanmate.ai.client.DietRecognitionClient;
import com.leanmate.ai.dto.DietRecognitionItem;
import com.leanmate.ai.dto.DietRecognitionResult;
import com.leanmate.ai.dto.DietTextRecognitionInput;
import com.leanmate.common.config.LimitProperties;
import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.diet.domain.FoodEntrySourceType;
import com.leanmate.diet.domain.MealType;
import com.leanmate.diet.domain.RecognitionTaskStatus;
import com.leanmate.diet.dto.PhotoRecognitionRequest;
import com.leanmate.diet.dto.RecognitionTaskResponse;
import com.leanmate.diet.dto.TextRecognitionRequest;
import com.leanmate.diet.repository.AiRecognitionTaskEntity;
import com.leanmate.diet.repository.AiRecognitionTaskRepository;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.repository.UserEntity;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DietRecognitionApplicationServiceTests {

    private static final UUID USER_ID = UUID.fromString("11111111-2222-3333-4444-555555555555");
    private static final UUID OTHER_USER_ID = UUID.fromString("99999999-2222-3333-4444-555555555555");
    private static final UUID TASK_ID = UUID.fromString("aaaaaaaa-1111-2222-3333-444444444444");

    private CurrentUserApplicationService currentUserApplicationService;
    private UserProfileRepository userProfileRepository;
    private AiRecognitionTaskRepository aiRecognitionTaskRepository;
    private DietRecognitionClient dietRecognitionClient;
    private DietRecognitionApplicationService dietRecognitionApplicationService;

    @BeforeEach
    void setUp() {
        currentUserApplicationService = mock(CurrentUserApplicationService.class);
        userProfileRepository = mock(UserProfileRepository.class);
        aiRecognitionTaskRepository = mock(AiRecognitionTaskRepository.class);
        dietRecognitionClient = mock(DietRecognitionClient.class);
        dietRecognitionApplicationService = new DietRecognitionApplicationService(
                currentUserApplicationService,
                userProfileRepository,
                aiRecognitionTaskRepository,
                dietRecognitionClient,
                new ObjectMapper().findAndRegisterModules(),
                new LimitProperties(8, 30, 3),
                Clock.fixed(Instant.parse("2026-06-07T00:00:00Z"), ZoneOffset.UTC));

        when(currentUserApplicationService.requireActiveUser(USER_ID)).thenReturn(new UserEntity());
        when(userProfileRepository.findByUserId(USER_ID)).thenReturn(Optional.of(profile()));
        when(aiRecognitionTaskRepository.save(any(AiRecognitionTaskEntity.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void createTextTaskAndReturnDraftEntry() {
        when(dietRecognitionClient.recognizeText(any(DietTextRecognitionInput.class)))
                .thenReturn(new DietRecognitionResult(
                        "test-text-model",
                        List.of(new DietRecognitionItem(
                                "鸡蛋",
                                "2个",
                                new BigDecimal("100.123"),
                                140,
                                new BigDecimal("12.345"),
                                new BigDecimal("10"),
                                new BigDecimal("1"),
                                new BigDecimal("0.82666"))),
                        "识别完成",
                        Map.of("provider", "test")));

        RecognitionTaskResponse response = dietRecognitionApplicationService.createTextTask(
                USER_ID,
                new TextRecognitionRequest(" 早餐吃了两个鸡蛋 ", MealType.BREAKFAST, LocalDate.parse("2026-06-07")));

        assertThat(response.sourceType()).isEqualTo(FoodEntrySourceType.TEXT);
        assertThat(response.status()).isEqualTo(RecognitionTaskStatus.SUCCEEDED);
        assertThat(response.mealDate()).isEqualTo(LocalDate.parse("2026-06-07"));
        assertThat(response.draftEntry()).isNotNull();
        assertThat(response.draftEntry().items()).hasSize(1);
        assertThat(response.draftEntry().items().get(0).name()).isEqualTo("鸡蛋");
        assertThat(response.draftEntry().items().get(0).weightG()).isEqualByComparingTo("100.12");
        assertThat(response.draftEntry().items().get(0).confidence()).isEqualByComparingTo("0.8267");
        assertThat(response.errorCode()).isNull();
        assertThat(response.finishedAt()).isNotNull();
    }

    @Test
    void createTaskKeepsFailedStatusWhenProviderFails() {
        when(dietRecognitionClient.recognizeText(any(DietTextRecognitionInput.class)))
                .thenThrow(new AiProviderException("provider_timeout", "AI 服务超时"));

        RecognitionTaskResponse response = dietRecognitionApplicationService.createTextTask(
                USER_ID,
                new TextRecognitionRequest("午餐一碗面", MealType.LUNCH, LocalDate.parse("2026-06-07")));

        assertThat(response.status()).isEqualTo(RecognitionTaskStatus.FAILED);
        assertThat(response.draftEntry()).isNull();
        assertThat(response.errorCode()).isEqualTo("provider_timeout");
        assertThat(response.errorMessage()).isEqualTo("AI 服务超时");
    }

    @Test
    void rejectUnsupportedPhotoTypeBeforeCallingAiProvider() {
        PhotoRecognitionRequest request = new PhotoRecognitionRequest(
                "food.gif",
                "image/gif",
                100,
                MealType.DINNER,
                LocalDate.parse("2026-06-07"),
                null);

        assertThatThrownBy(() -> dietRecognitionApplicationService.createPhotoTask(USER_ID, request))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.BAD_REQUEST);
        verifyNoInteractions(dietRecognitionClient);
    }

    @Test
    void rejectOtherUserTask() {
        AiRecognitionTaskEntity task = new AiRecognitionTaskEntity();
        task.setId(TASK_ID);
        task.setUserId(OTHER_USER_ID);
        task.setSourceType(FoodEntrySourceType.TEXT.value());
        task.setStatus(RecognitionTaskStatus.SUCCEEDED.value());
        task.setCreatedAt(Instant.parse("2026-06-07T00:00:00Z"));
        when(aiRecognitionTaskRepository.findById(TASK_ID)).thenReturn(Optional.of(task));

        assertThatThrownBy(() -> dietRecognitionApplicationService.getTask(USER_ID, TASK_ID))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.FORBIDDEN);
    }

    private UserProfileEntity profile() {
        UserProfileEntity profile = new UserProfileEntity();
        profile.setUserId(USER_ID);
        profile.setTimezone("Asia/Shanghai");
        profile.setDailyCalorieTargetKcal(1800);
        return profile;
    }
}
