package com.leanmate.diet.application;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.leanmate.ai.client.AiProviderException;
import com.leanmate.ai.client.DietRecognitionClient;
import com.leanmate.ai.dto.DietPhotoRecognitionInput;
import com.leanmate.ai.dto.DietRecognitionItem;
import com.leanmate.ai.dto.DietRecognitionResult;
import com.leanmate.ai.dto.DietTextRecognitionInput;
import com.leanmate.common.config.LimitProperties;
import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.diet.domain.FoodEntrySourceType;
import com.leanmate.diet.domain.NutritionSource;
import com.leanmate.diet.domain.MealType;
import com.leanmate.diet.domain.RecognitionTaskStatus;
import com.leanmate.diet.dto.FoodEntryDraftResponse;
import com.leanmate.diet.dto.FoodItemResponse;
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
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import java.util.ArrayList;
import java.util.Comparator;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.DateTimeException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class DietRecognitionApplicationService {

    private static final Logger log = LoggerFactory.getLogger(DietRecognitionApplicationService.class);
    private static final Set<String> ALLOWED_IMAGE_CONTENT_TYPES = Set.of(
            "image/jpeg",
            "image/png",
            "image/webp",
            "image/heic",
            "image/heif");
    private static final BigDecimal HUNDRED = new BigDecimal("100");
    private static final BigDecimal TEXT_FALLBACK_CONFIDENCE = new BigDecimal("0.6500");
    private static final Pattern TEXT_ITEM_SPLIT_PATTERN = Pattern.compile("[,，、;；\\n]+|和(?=一|半|两|俩|[0-9])");
    private static final Pattern WEIGHT_PATTERN = Pattern.compile(
            "(?:约|大约|大概|差不多)?\\s*(\\d+(?:\\.\\d+)?)\\s*(?:g|G|克|毫升|ml|mL|ML)");
    private static final Pattern QUANTITY_HINT_PATTERN = Pattern.compile(
            "[一二三四五六七八九十两俩半0-9]+\\s*(碗|杯|个|份|根|块|小把|掌心|勺)");
    private static final Pattern MEASURE_PAREN_PATTERN = Pattern.compile(
            "[（(]\\s*(?:约|大约|大概|差不多)?\\s*\\d+(?:\\.\\d+)?\\s*(?:g|G|克|毫升|ml|mL|ML)\\s*[）)]");
    private static final Pattern STANDALONE_MEASURE_PATTERN = Pattern.compile(
            "(?:约|大约|大概|差不多)?\\s*\\d+(?:\\.\\d+)?\\s*(?:g|G|克|毫升|ml|mL|ML)");

    private final CurrentUserApplicationService currentUserApplicationService;
    private final UserProfileRepository userProfileRepository;
    private final AiRecognitionTaskRepository aiRecognitionTaskRepository;
    private final FoodCatalogRepository foodCatalogRepository;
    private final FoodPortionRepository foodPortionRepository;
    private final DietRecognitionClient dietRecognitionClient;
    private final ObjectMapper objectMapper;
    private final LimitProperties limitProperties;
    private final Clock clock;

    @Autowired
    public DietRecognitionApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            AiRecognitionTaskRepository aiRecognitionTaskRepository,
            FoodCatalogRepository foodCatalogRepository,
            FoodPortionRepository foodPortionRepository,
            DietRecognitionClient dietRecognitionClient,
            ObjectMapper objectMapper,
            LimitProperties limitProperties
    ) {
        this(
                currentUserApplicationService,
                userProfileRepository,
                aiRecognitionTaskRepository,
                foodCatalogRepository,
                foodPortionRepository,
                dietRecognitionClient,
                objectMapper,
                limitProperties,
                Clock.systemUTC());
    }

    DietRecognitionApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            AiRecognitionTaskRepository aiRecognitionTaskRepository,
            FoodCatalogRepository foodCatalogRepository,
            FoodPortionRepository foodPortionRepository,
            DietRecognitionClient dietRecognitionClient,
            ObjectMapper objectMapper,
            LimitProperties limitProperties,
            Clock clock
    ) {
        this.currentUserApplicationService = currentUserApplicationService;
        this.userProfileRepository = userProfileRepository;
        this.aiRecognitionTaskRepository = aiRecognitionTaskRepository;
        this.foodCatalogRepository = foodCatalogRepository;
        this.foodPortionRepository = foodPortionRepository;
        this.dietRecognitionClient = dietRecognitionClient;
        this.objectMapper = objectMapper;
        this.limitProperties = limitProperties;
        this.clock = clock;
    }

    public RecognitionTaskResponse createPhotoTask(UUID userId, PhotoRecognitionRequest request) {
        currentUserApplicationService.requireActiveUser(userId);
        UserProfileEntity profile = requireProfile(userId);
        validateImage(request);
        LocalDate mealDate = resolveMealDate(request.mealDate(), profile);
        UUID taskId = UUID.randomUUID();
        String objectKey = imageObjectKey(userId, taskId, request.contentType());

        AiRecognitionTaskEntity task = newTask(
                taskId,
                userId,
                FoodEntrySourceType.PHOTO,
                mealDate,
                request.mealType(),
                trimToNull(request.note()));
        task.setInputObjectKey(objectKey);
        AiRecognitionTaskEntity savedTask = aiRecognitionTaskRepository.save(task);

        return runRecognition(savedTask, () -> dietRecognitionClient.recognizePhoto(new DietPhotoRecognitionInput(
                savedTask.getId(),
                userId,
                mealDate,
                request.mealType(),
                trimToNull(request.note()),
                objectKey,
                request.contentType(),
                request.imageSizeBytes())));
    }

    public RecognitionTaskResponse createTextTask(UUID userId, TextRecognitionRequest request) {
        currentUserApplicationService.requireActiveUser(userId);
        UserProfileEntity profile = requireProfile(userId);
        LocalDate mealDate = resolveMealDate(request.mealDate(), profile);
        String text = request.text().trim();

        AiRecognitionTaskEntity task = newTask(
                UUID.randomUUID(),
                userId,
                FoodEntrySourceType.TEXT,
                mealDate,
                request.mealType(),
                text);
        AiRecognitionTaskEntity savedTask = aiRecognitionTaskRepository.save(task);

        return runRecognition(savedTask, () -> dietRecognitionClient.recognizeText(new DietTextRecognitionInput(
                savedTask.getId(),
                userId,
                mealDate,
                request.mealType(),
                text)));
    }

    @Transactional(readOnly = true)
    public RecognitionTaskResponse getTask(UUID userId, UUID taskId) {
        currentUserApplicationService.requireActiveUser(userId);
        AiRecognitionTaskEntity task = aiRecognitionTaskRepository.findById(taskId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND));
        if (!task.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        return toResponse(task);
    }

    private RecognitionTaskResponse runRecognition(
            AiRecognitionTaskEntity task,
            Supplier<DietRecognitionResult> recognitionSupplier
    ) {
        task.setStatus(RecognitionTaskStatus.RUNNING.value());
        task.setStartedAt(Instant.now(clock));
        aiRecognitionTaskRepository.save(task);

        try {
            DietRecognitionResult result = recognitionSupplier.get();
            applySuccess(task, result);
        } catch (AiProviderException exception) {
            applyFailure(task, exception.providerErrorCode(), safeErrorMessage(exception.getMessage()));
        } catch (RuntimeException exception) {
            log.warn("饮食 AI 识别失败 taskId={}, error={}", task.getId(), exception.getClass().getName());
            applyFailure(task, "ai_provider_error", ErrorCode.AI_SERVICE_ERROR.message());
        }

        AiRecognitionTaskEntity savedTask = aiRecognitionTaskRepository.save(task);
        return toResponse(savedTask);
    }

    private AiRecognitionTaskEntity newTask(
            UUID taskId,
            UUID userId,
            FoodEntrySourceType sourceType,
            LocalDate mealDate,
            MealType mealType,
            String inputText
    ) {
        Instant now = Instant.now(clock);
        AiRecognitionTaskEntity task = new AiRecognitionTaskEntity();
        task.setId(taskId);
        task.setUserId(userId);
        task.setSourceType(sourceType.value());
        task.setMealDate(mealDate);
        task.setMealType(mealType.value());
        task.setInputText(inputText);
        task.setStatus(RecognitionTaskStatus.PENDING.value());
        task.setCreatedAt(now);
        return task;
    }

    private void applySuccess(AiRecognitionTaskEntity task, DietRecognitionResult result) {
        task.setStatus(RecognitionTaskStatus.SUCCEEDED.value());
        task.setModelName(trimToNull(result.modelName()));
        task.setErrorCode(null);
        task.setErrorMessage(null);
        task.setRawOutput(result.rawOutput());

        List<DietRecognitionItem> normalizedItems = normalizeRecognitionItems(task, result.items());
        StoredFoodEntryDraft draft = new StoredFoodEntryDraft(
                task.getMealDate(),
                MealType.fromValue(task.getMealType()),
                FoodEntrySourceType.fromValue(task.getSourceType()),
                normalizedItems.stream()
                        .map(this::toCandidateResponse)
                        .toList(),
                trimToNull(result.notes()));
        task.setStructuredResult(toMap(draft));
        task.setFinishedAt(Instant.now(clock));
    }

    private void applyFailure(AiRecognitionTaskEntity task, String errorCode, String errorMessage) {
        String safeErrorCode = StringUtils.hasText(errorCode) ? errorCode : "ai_provider_error";
        task.setStatus(RecognitionTaskStatus.FAILED.value());
        task.setErrorCode(safeErrorCode);
        task.setErrorMessage(errorMessage);
        task.setStructuredResult(null);
        task.setRawOutput(Map.of(
                "errorCode", safeErrorCode,
                "errorMessage", errorMessage));
        task.setFinishedAt(Instant.now(clock));
    }

    private FoodItemResponse toCandidateResponse(DietRecognitionItem item) {
        return new FoodItemResponse(
                UUID.randomUUID(),
                StringUtils.hasText(item.name()) ? item.name().trim() : "未命名食物",
                trimToNull(item.quantityText()),
                scale(item.weightG(), 2),
                item.caloriesKcal(),
                scale(item.proteinG(), 2),
                scale(item.fatG(), 2),
                scale(item.carbsG(), 2),
                scale(item.confidence(), 4),
                false,
                matchedFoodId(item),
                NutritionSource.AI_ESTIMATED);
    }

    private List<DietRecognitionItem> normalizeRecognitionItems(
            AiRecognitionTaskEntity task,
            List<DietRecognitionItem> items
    ) {
        List<DietRecognitionItem> safeItems = items == null ? List.of() : items;
        if (FoodEntrySourceType.TEXT.value().equals(task.getSourceType())) {
            safeItems = splitMergedTextItems(task.getInputText(), safeItems);
        }
        return safeItems.stream()
                .map(this::enrichTextNutrition)
                .toList();
    }

    private List<DietRecognitionItem> splitMergedTextItems(String inputText, List<DietRecognitionItem> items) {
        if (items.size() != 1 || !StringUtils.hasText(inputText)) {
            return items;
        }

        DietRecognitionItem onlyItem = items.get(0);
        if (!hasMultipleTextSegments(inputText)
                || (!looksLikeMergedTextItem(inputText, onlyItem) && hasAnyNutrition(onlyItem))) {
            return items;
        }

        List<DietRecognitionItem> fallbackItems = splitTextSegments(inputText).stream()
                .map(this::fallbackItemFromTextSegment)
                .filter(Objects::nonNull)
                .toList();
        return fallbackItems.size() > 1 ? fallbackItems : items;
    }

    private boolean hasMultipleTextSegments(String inputText) {
        return splitTextSegments(inputText).size() > 1;
    }

    private boolean looksLikeMergedTextItem(String inputText, DietRecognitionItem item) {
        String itemName = item.name();
        if (!StringUtils.hasText(itemName)) {
            return false;
        }
        String normalizedName = normalize(itemName);
        String normalizedInput = normalize(inputText);
        return normalizedName.equals(normalizedInput)
                || normalizedName.contains(normalizedInput)
                || containsTextSeparator(itemName);
    }

    private boolean containsTextSeparator(String value) {
        return StringUtils.hasText(value)
                && Pattern.compile("[,，、;；\\n]").matcher(value).find();
    }

    private boolean hasAnyNutrition(DietRecognitionItem item) {
        return item.weightG() != null
                || item.caloriesKcal() != null
                || item.proteinG() != null
                || item.fatG() != null
                || item.carbsG() != null;
    }

    private List<String> splitTextSegments(String inputText) {
        if (!StringUtils.hasText(inputText)) {
            return List.of();
        }
        List<String> segments = new ArrayList<>();
        for (String segment : TEXT_ITEM_SPLIT_PATTERN.split(inputText)) {
            String normalizedSegment = trimToNull(segment);
            if (normalizedSegment != null) {
                segments.add(normalizedSegment);
            }
        }
        return segments;
    }

    private DietRecognitionItem fallbackItemFromTextSegment(String segment) {
        FoodCatalogEntity food = matchFood(segment);
        if (food == null) {
            return null;
        }
        BigDecimal weightG = resolveWeight(segment, food);
        return new DietRecognitionItem(
                food.getName(),
                quantityTextFromSegment(segment, food),
                weightG,
                null,
                null,
                null,
                null,
                TEXT_FALLBACK_CONFIDENCE);
    }

    private DietRecognitionItem enrichTextNutrition(DietRecognitionItem item) {
        FoodCatalogEntity food = matchFood(item.name());
        if (food == null && StringUtils.hasText(item.quantityText())) {
            food = matchFood(item.quantityText());
        }
        if (food == null) {
            return item;
        }

        BigDecimal weightG = item.weightG();
        if (weightG == null) {
            weightG = parseWeight(item.quantityText());
        }
        if (weightG == null) {
            weightG = parseWeight(item.name());
        }
        DefaultPortion defaultPortion = null;
        if (weightG == null) {
            defaultPortion = defaultPortion(food);
            weightG = defaultPortion == null ? null : defaultPortion.weightG();
        }

        NutritionEstimate nutrition = weightG == null ? null : estimateNutrition(food, weightG);
        String originalName = trimToNull(item.name());
        String quantityText = trimToNull(item.quantityText());
        if (quantityText == null && defaultPortion != null) {
            quantityText = defaultPortion.label();
        }
        if (quantityText == null && originalName != null && !normalize(originalName).equals(normalize(food.getName()))) {
            quantityText = originalName;
        }
        quantityText = normalizedQuantityText(quantityText, food);

        return new DietRecognitionItem(
                food.getName(),
                quantityText,
                weightG == null ? null : scale(weightG, 2),
                item.caloriesKcal() == null && nutrition != null ? nutrition.caloriesKcal() : item.caloriesKcal(),
                item.proteinG() == null && nutrition != null ? nutrition.proteinG() : item.proteinG(),
                item.fatG() == null && nutrition != null ? nutrition.fatG() : item.fatG(),
                item.carbsG() == null && nutrition != null ? nutrition.carbsG() : item.carbsG(),
                item.confidence() == null ? TEXT_FALLBACK_CONFIDENCE : item.confidence());
    }

    private FoodCatalogEntity matchFood(String text) {
        String normalizedText = normalize(text);
        if (!StringUtils.hasText(normalizedText)) {
            return null;
        }

        FoodCatalogEntity containedMatch = foodCatalogRepository.findAll().stream()
                .filter(food -> Boolean.TRUE.equals(food.getVerified()))
                .filter(food -> StringUtils.hasText(food.getNormalizedName()))
                .filter(food -> normalizedText.contains(food.getNormalizedName()))
                .max(Comparator.comparingInt(food -> food.getNormalizedName().length()))
                .orElse(null);
        if (containedMatch != null) {
            return containedMatch;
        }

        return foodCatalogRepository.searchVerified(normalizedText, PageRequest.of(0, 1))
                .stream()
                .findFirst()
                .orElse(null);
    }

    private BigDecimal resolveWeight(String text, FoodCatalogEntity food) {
        BigDecimal parsedWeight = parseWeight(text);
        if (parsedWeight != null) {
            return parsedWeight;
        }
        DefaultPortion defaultPortion = defaultPortion(food);
        return defaultPortion == null ? null : defaultPortion.weightG();
    }

    private BigDecimal parseWeight(String text) {
        if (!StringUtils.hasText(text)) {
            return null;
        }
        Matcher matcher = WEIGHT_PATTERN.matcher(text);
        if (!matcher.find()) {
            return null;
        }
        return new BigDecimal(matcher.group(1)).setScale(2, RoundingMode.HALF_UP);
    }

    private String quantityTextFromSegment(String segment, FoodCatalogEntity food) {
        String trimmedSegment = trimToNull(segment);
        if (trimmedSegment == null || normalize(trimmedSegment).equals(normalize(food.getName()))) {
            return null;
        }
        if (parseWeight(trimmedSegment) != null || QUANTITY_HINT_PATTERN.matcher(trimmedSegment).find()) {
            return normalizedQuantityText(trimmedSegment, food);
        }
        return null;
    }

    private String normalizedQuantityText(String value, FoodCatalogEntity food) {
        String normalizedValue = trimToNull(value);
        if (normalizedValue == null) {
            return null;
        }

        normalizedValue = MEASURE_PAREN_PATTERN.matcher(normalizedValue).replaceAll("");
        normalizedValue = STANDALONE_MEASURE_PATTERN.matcher(normalizedValue).replaceAll("");
        if (StringUtils.hasText(food.getName())) {
            normalizedValue = normalizedValue.replace(food.getName(), "");
        }
        normalizedValue = normalizedValue
                .replaceAll("[,，、;；。\\s]+", "")
                .trim();
        if (!StringUtils.hasText(normalizedValue) || normalize(normalizedValue).equals(normalize(food.getName()))) {
            return null;
        }
        return normalizedValue;
    }

    private DefaultPortion defaultPortion(FoodCatalogEntity food) {
        return foodPortionRepository.findByFoodIdAndDefaultPortionTrue(food.getId())
                .map(portion -> new DefaultPortion(portion.getLabel(), portion.getGramWeight()))
                .orElse(null);
    }

    private NutritionEstimate estimateNutrition(FoodCatalogEntity food, BigDecimal weightG) {
        BigDecimal factor = weightG.divide(HUNDRED, 6, RoundingMode.HALF_UP);
        return new NutritionEstimate(
                new BigDecimal(food.getCaloriesPer100g()).multiply(factor).setScale(0, RoundingMode.HALF_UP).intValue(),
                scale(food.getProteinPer100g().multiply(factor), 2),
                scale(food.getFatPer100g().multiply(factor), 2),
                scale(food.getCarbsPer100g().multiply(factor), 2));
    }

    private UUID matchedFoodId(DietRecognitionItem item) {
        String normalizedName = normalize(item.name());
        if (!StringUtils.hasText(normalizedName)) {
            return null;
        }
        return foodCatalogRepository.searchVerified(normalizedName, PageRequest.of(0, 1))
                .stream()
                .findFirst()
                .map(FoodCatalogEntity::getId)
                .orElse(null);
    }

    private RecognitionTaskResponse toResponse(AiRecognitionTaskEntity task) {
        return new RecognitionTaskResponse(
                task.getId(),
                FoodEntrySourceType.fromValue(task.getSourceType()),
                task.getMealDate(),
                task.getMealType() == null ? null : MealType.fromValue(task.getMealType()),
                RecognitionTaskStatus.fromValue(task.getStatus()),
                draftEntry(task),
                task.getErrorCode(),
                task.getErrorMessage(),
                task.getCreatedAt(),
                task.getFinishedAt());
    }

    private FoodEntryDraftResponse draftEntry(AiRecognitionTaskEntity task) {
        if (task.getStructuredResult() == null) {
            return null;
        }
        StoredFoodEntryDraft draft = objectMapper.convertValue(
                task.getStructuredResult(),
                StoredFoodEntryDraft.class);
        return new FoodEntryDraftResponse(
                draft.mealDate(),
                draft.mealType(),
                draft.sourceType(),
                draft.items());
    }

    private Map<String, Object> toMap(StoredFoodEntryDraft draft) {
        return objectMapper.convertValue(draft, new TypeReference<>() {
        });
    }

    private void validateImage(PhotoRecognitionRequest request) {
        if (request.imageSizeBytes() <= 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "image 不能为空");
        }
        if (request.imageSizeBytes() > limitProperties.maxUploadImageSizeBytes()) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "图片大小超过限制");
        }
        if (!StringUtils.hasText(request.contentType())
                || !ALLOWED_IMAGE_CONTENT_TYPES.contains(request.contentType().toLowerCase())) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "图片类型不支持");
        }
    }

    private LocalDate resolveMealDate(LocalDate mealDate, UserProfileEntity profile) {
        LocalDate resolvedDate = mealDate == null ? LocalDate.now(clock.withZone(zoneId(profile))) : mealDate;
        LocalDate today = LocalDate.now(clock.withZone(zoneId(profile)));
        if (resolvedDate.isAfter(today)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "饮食识别日期不能晚于今天");
        }
        return resolvedDate;
    }

    private UserProfileEntity requireProfile(UUID userId) {
        return userProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.BAD_REQUEST, "请先完成用户档案"));
    }

    private ZoneId zoneId(UserProfileEntity profile) {
        try {
            return ZoneId.of(profile.getTimezone());
        } catch (DateTimeException exception) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "timezone 无效");
        }
    }

    private String imageObjectKey(UUID userId, UUID taskId, String contentType) {
        return "diet-recognitions/%s/%s%s".formatted(userId, taskId, extension(contentType));
    }

    private String extension(String contentType) {
        return switch (contentType.toLowerCase()) {
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            case "image/heic" -> ".heic";
            case "image/heif" -> ".heif";
            default -> ".jpg";
        };
    }

    private String safeErrorMessage(String message) {
        return StringUtils.hasText(message) ? message : ErrorCode.AI_SERVICE_ERROR.message();
    }

    private BigDecimal scale(BigDecimal value, int scale) {
        if (value == null) {
            return null;
        }
        return value.setScale(scale, RoundingMode.HALF_UP);
    }

    private String trimToNull(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        return value.trim();
    }

    private String normalize(String value) {
        if (value == null) {
            return "";
        }
        return value.trim().toLowerCase().replaceAll("\\s+", "");
    }

    private record StoredFoodEntryDraft(
            LocalDate mealDate,
            MealType mealType,
            FoodEntrySourceType sourceType,
            List<FoodItemResponse> items,
            String notes
    ) {
    }

    private record NutritionEstimate(
            Integer caloriesKcal,
            BigDecimal proteinG,
            BigDecimal fatG,
            BigDecimal carbsG
    ) {
    }

    private record DefaultPortion(
            String label,
            BigDecimal weightG
    ) {
    }
}
