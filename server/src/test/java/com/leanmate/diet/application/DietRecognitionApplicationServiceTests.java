package com.leanmate.diet.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
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
import com.leanmate.food.repository.FoodCatalogEntity;
import com.leanmate.food.repository.FoodCatalogRepository;
import com.leanmate.food.repository.FoodPortionEntity;
import com.leanmate.food.repository.FoodPortionRepository;
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
import org.springframework.data.domain.Pageable;

class DietRecognitionApplicationServiceTests {

    private static final UUID USER_ID = UUID.fromString("11111111-2222-3333-4444-555555555555");
    private static final UUID OTHER_USER_ID = UUID.fromString("99999999-2222-3333-4444-555555555555");
    private static final UUID TASK_ID = UUID.fromString("aaaaaaaa-1111-2222-3333-444444444444");
    private static final UUID EGG_FOOD_ID = UUID.fromString("0a1b8ef0-6ec2-429e-b615-2da2b3463af3");

    private CurrentUserApplicationService currentUserApplicationService;
    private UserProfileRepository userProfileRepository;
    private AiRecognitionTaskRepository aiRecognitionTaskRepository;
    private FoodCatalogRepository foodCatalogRepository;
    private FoodPortionRepository foodPortionRepository;
    private DietRecognitionClient dietRecognitionClient;
    private DietRecognitionApplicationService dietRecognitionApplicationService;

    @BeforeEach
    void setUp() {
        currentUserApplicationService = mock(CurrentUserApplicationService.class);
        userProfileRepository = mock(UserProfileRepository.class);
        aiRecognitionTaskRepository = mock(AiRecognitionTaskRepository.class);
        foodCatalogRepository = mock(FoodCatalogRepository.class);
        foodPortionRepository = mock(FoodPortionRepository.class);
        dietRecognitionClient = mock(DietRecognitionClient.class);
        dietRecognitionApplicationService = new DietRecognitionApplicationService(
                currentUserApplicationService,
                userProfileRepository,
                aiRecognitionTaskRepository,
                foodCatalogRepository,
                foodPortionRepository,
                dietRecognitionClient,
                new ObjectMapper().findAndRegisterModules(),
                new LimitProperties(8, 30, 3),
                Clock.fixed(Instant.parse("2026-06-07T00:00:00Z"), ZoneOffset.UTC));

        when(currentUserApplicationService.requireActiveUser(USER_ID)).thenReturn(new UserEntity());
        when(userProfileRepository.findByUserId(USER_ID)).thenReturn(Optional.of(profile()));
        when(aiRecognitionTaskRepository.save(any(AiRecognitionTaskEntity.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(foodCatalogRepository.searchVerified(any(), any(Pageable.class))).thenReturn(List.of());
        when(foodCatalogRepository.findAll()).thenReturn(List.of());
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
        when(foodCatalogRepository.searchVerified(eq("鸡蛋"), any(Pageable.class))).thenReturn(List.of(eggFood()));

        RecognitionTaskResponse response = dietRecognitionApplicationService.createTextTask(
                USER_ID,
                new TextRecognitionRequest(" 早餐吃了两个鸡蛋 ", MealType.BREAKFAST, LocalDate.parse("2026-06-07")));

        assertThat(response.sourceType()).isEqualTo(FoodEntrySourceType.TEXT);
        assertThat(response.status()).isEqualTo(RecognitionTaskStatus.SUCCEEDED);
        assertThat(response.mealDate()).isEqualTo(LocalDate.parse("2026-06-07"));
        assertThat(response.draftEntry()).isNotNull();
        assertThat(response.draftEntry().items()).hasSize(1);
        assertThat(response.draftEntry().items().get(0).name()).isEqualTo("鸡蛋");
        assertThat(response.draftEntry().items().get(0).foodId()).isEqualTo(EGG_FOOD_ID);
        assertThat(response.draftEntry().items().get(0).nutritionSource().value()).isEqualTo("ai_estimated");
        assertThat(response.draftEntry().items().get(0).weightG()).isEqualByComparingTo("100.12");
        assertThat(response.draftEntry().items().get(0).confidence()).isEqualByComparingTo("0.8267");
        assertThat(response.errorCode()).isNull();
        assertThat(response.finishedAt()).isNotNull();
    }

    @Test
    void createTextTaskSplitsMergedTextResultAndFillsNutritionFromFoodCatalog() {
        when(dietRecognitionClient.recognizeText(any(DietTextRecognitionInput.class)))
                .thenReturn(new DietRecognitionResult(
                        "deepseek-v4-flash",
                        List.of(new DietRecognitionItem(
                                "一碗米饭（约180g），一个鸡蛋（约55g），一杯豆浆（约250ml）",
                                null,
                                null,
                                null,
                                null,
                                null,
                                null,
                                new BigDecimal("0.30"))),
                        "按常见食物估算。",
                        Map.of("provider", "deepseek")));
        when(foodCatalogRepository.findAll()).thenReturn(List.of(riceFood(), eggFood(), soyMilkFood()));
        when(foodCatalogRepository.searchVerified(eq("米饭"), any(Pageable.class))).thenReturn(List.of(riceFood()));
        when(foodCatalogRepository.searchVerified(eq("鸡蛋"), any(Pageable.class))).thenReturn(List.of(eggFood()));
        when(foodCatalogRepository.searchVerified(eq("豆浆"), any(Pageable.class))).thenReturn(List.of(soyMilkFood()));

        RecognitionTaskResponse response = dietRecognitionApplicationService.createTextTask(
                USER_ID,
                new TextRecognitionRequest(
                        "一碗米饭（约180g），一个鸡蛋（约55g），一杯豆浆（约250ml）",
                        MealType.DINNER,
                        LocalDate.parse("2026-06-07")));

        assertThat(response.status()).isEqualTo(RecognitionTaskStatus.SUCCEEDED);
        assertThat(response.draftEntry()).isNotNull();
        assertThat(response.draftEntry().items()).hasSize(3);
        assertThat(response.draftEntry().items()).extracting("name")
                .containsExactly("米饭", "鸡蛋", "豆浆");
        assertThat(response.draftEntry().items()).extracting("quantityText")
                .containsExactly("一碗", "一个", "一杯");
        assertThat(response.draftEntry().items()).extracting("weightG")
                .containsExactly(new BigDecimal("180.00"), new BigDecimal("55.00"), new BigDecimal("250.00"));
        assertThat(response.draftEntry().items()).extracting("caloriesKcal")
                .containsExactly(209, 79, 78);
        assertThat(response.draftEntry().items().get(0).proteinG()).isEqualByComparingTo("4.68");
        assertThat(response.draftEntry().items().get(1).proteinG()).isEqualByComparingTo("6.93");
        assertThat(response.draftEntry().items().get(2).proteinG()).isEqualByComparingTo("7.50");
    }

    @Test
    void createTextTaskUsesDefaultDrinkPortionLabelWhenQuantityIsMissing() {
        when(dietRecognitionClient.recognizeText(any(DietTextRecognitionInput.class)))
                .thenReturn(new DietRecognitionResult(
                        "deepseek-v4-flash",
                        List.of(new DietRecognitionItem(
                                "豆浆",
                                null,
                                null,
                                null,
                                null,
                                null,
                                null,
                                new BigDecimal("0.70"))),
                        "按默认份量估算。",
                        Map.of("provider", "deepseek")));
        when(foodCatalogRepository.findAll()).thenReturn(List.of(soyMilkFood()));
        when(foodPortionRepository.findByFoodIdAndDefaultPortionTrue(soyMilkFood().getId()))
                .thenReturn(Optional.of(defaultPortion(
                        soyMilkFood().getId(),
                        "一杯（约250ml）",
                        new BigDecimal("250.00"))));

        RecognitionTaskResponse response = dietRecognitionApplicationService.createTextTask(
                USER_ID,
                new TextRecognitionRequest("豆浆", MealType.BREAKFAST, LocalDate.parse("2026-06-07")));

        assertThat(response.status()).isEqualTo(RecognitionTaskStatus.SUCCEEDED);
        assertThat(response.draftEntry().items()).hasSize(1);
        assertThat(response.draftEntry().items().get(0).name()).isEqualTo("豆浆");
        assertThat(response.draftEntry().items().get(0).quantityText()).isEqualTo("一杯");
        assertThat(response.draftEntry().items().get(0).weightG()).isEqualByComparingTo("250.00");
        assertThat(response.draftEntry().items().get(0).caloriesKcal()).isEqualTo(78);
    }

    @Test
    void createTextTaskStripsWeightFromProviderQuantityText() {
        when(dietRecognitionClient.recognizeText(any(DietTextRecognitionInput.class)))
                .thenReturn(new DietRecognitionResult(
                        "deepseek-v4-flash",
                        List.of(
                                new DietRecognitionItem(
                                        "鸡蛋",
                                        "一个（约55g）",
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        new BigDecimal("0.82")),
                                new DietRecognitionItem(
                                        "豆浆",
                                        "一杯豆浆（约250ml）",
                                        null,
                                        null,
                                        null,
                                        null,
                                        null,
                                        new BigDecimal("0.80"))),
                        "按默认份量估算。",
                        Map.of("provider", "deepseek")));
        when(foodCatalogRepository.findAll()).thenReturn(List.of(eggFood(), soyMilkFood()));

        RecognitionTaskResponse response = dietRecognitionApplicationService.createTextTask(
                USER_ID,
                new TextRecognitionRequest("早餐一个鸡蛋一杯豆浆", MealType.BREAKFAST, LocalDate.parse("2026-06-07")));

        assertThat(response.status()).isEqualTo(RecognitionTaskStatus.SUCCEEDED);
        assertThat(response.draftEntry().items()).extracting("name")
                .containsExactly("鸡蛋", "豆浆");
        assertThat(response.draftEntry().items()).extracting("quantityText")
                .containsExactly("一个", "一杯");
        assertThat(response.draftEntry().items()).extracting("weightG")
                .containsExactly(new BigDecimal("55.00"), new BigDecimal("250.00"));
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

    private FoodCatalogEntity eggFood() {
        FoodCatalogEntity food = new FoodCatalogEntity();
        food.setId(EGG_FOOD_ID);
        food.setName("鸡蛋");
        food.setNormalizedName("鸡蛋");
        food.setCategory("protein");
        food.setCaloriesPer100g(143);
        food.setProteinPer100g(new BigDecimal("12.60"));
        food.setFatPer100g(new BigDecimal("9.50"));
        food.setCarbsPer100g(new BigDecimal("0.70"));
        food.setSource("curated");
        food.setConfidence(new BigDecimal("1.0000"));
        food.setVerified(true);
        food.setLocale("zh-CN");
        return food;
    }

    private FoodCatalogEntity riceFood() {
        FoodCatalogEntity food = new FoodCatalogEntity();
        food.setId(UUID.fromString("ae5064cd-b812-4df7-bc0d-22634e99356e"));
        food.setName("米饭");
        food.setNormalizedName("米饭");
        food.setCategory("staple");
        food.setCaloriesPer100g(116);
        food.setProteinPer100g(new BigDecimal("2.60"));
        food.setFatPer100g(new BigDecimal("0.30"));
        food.setCarbsPer100g(new BigDecimal("25.90"));
        food.setSource("curated");
        food.setConfidence(new BigDecimal("1.0000"));
        food.setVerified(true);
        food.setLocale("zh-CN");
        return food;
    }

    private FoodCatalogEntity soyMilkFood() {
        FoodCatalogEntity food = new FoodCatalogEntity();
        food.setId(UUID.fromString("917501f8-4a66-40c0-8813-27b91bf42176"));
        food.setName("豆浆");
        food.setNormalizedName("豆浆");
        food.setCategory("drink");
        food.setCaloriesPer100g(31);
        food.setProteinPer100g(new BigDecimal("3.00"));
        food.setFatPer100g(new BigDecimal("1.60"));
        food.setCarbsPer100g(new BigDecimal("1.20"));
        food.setSource("curated");
        food.setConfidence(new BigDecimal("1.0000"));
        food.setVerified(true);
        food.setLocale("zh-CN");
        return food;
    }

    private FoodPortionEntity defaultPortion(UUID foodId, String label, BigDecimal gramWeight) {
        FoodPortionEntity portion = new FoodPortionEntity();
        portion.setId(UUID.randomUUID());
        portion.setFoodId(foodId);
        portion.setLabel(label);
        portion.setGramWeight(gramWeight);
        portion.setDefaultPortion(true);
        portion.setSortOrder(0);
        return portion;
    }
}
