package com.leanmate.report.application;

import com.leanmate.ai.client.AiProviderException;
import com.leanmate.ai.client.DailyReportClient;
import com.leanmate.ai.dto.DailyReportFoodEntryInput;
import com.leanmate.ai.dto.DailyReportFoodItemInput;
import com.leanmate.ai.dto.DailyReportGoalInput;
import com.leanmate.ai.dto.DailyReportInput;
import com.leanmate.ai.dto.DailyReportProfileInput;
import com.leanmate.ai.dto.DailyReportResult;
import com.leanmate.ai.dto.DailyReportSnapshotInput;
import com.leanmate.ai.dto.DailyReportStreakInput;
import com.leanmate.ai.dto.DailyReportWeightEntryInput;
import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.diet.domain.FoodEntryStatus;
import com.leanmate.diet.repository.FoodEntryEntity;
import com.leanmate.diet.repository.FoodEntryRepository;
import com.leanmate.diet.repository.FoodItemEntity;
import com.leanmate.diet.repository.FoodItemRepository;
import com.leanmate.report.domain.DailyReportStatus;
import com.leanmate.report.dto.DailyReportResponse;
import com.leanmate.report.dto.GenerateDailyReportRequest;
import com.leanmate.report.repository.DailyAiReportEntity;
import com.leanmate.report.repository.DailyAiReportRepository;
import com.leanmate.stats.application.DailyNutritionSnapshotApplicationService;
import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.stats.repository.DailyNutritionSnapshotEntity;
import com.leanmate.stats.repository.DailyNutritionSnapshotRepository;
import com.leanmate.stats.repository.StreakEntity;
import com.leanmate.stats.repository.StreakRepository;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.domain.WeightGoalStatus;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.user.repository.WeightGoalEntity;
import com.leanmate.user.repository.WeightGoalRepository;
import com.leanmate.weight.repository.WeightEntryEntity;
import com.leanmate.weight.repository.WeightEntryRepository;
import java.time.Clock;
import java.time.DateTimeException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class DailyReportApplicationService {

    private static final Logger log = LoggerFactory.getLogger(DailyReportApplicationService.class);

    private final CurrentUserApplicationService currentUserApplicationService;
    private final UserProfileRepository userProfileRepository;
    private final WeightGoalRepository weightGoalRepository;
    private final WeightEntryRepository weightEntryRepository;
    private final FoodEntryRepository foodEntryRepository;
    private final FoodItemRepository foodItemRepository;
    private final DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService;
    private final DailyNutritionSnapshotRepository dailyNutritionSnapshotRepository;
    private final StreakRepository streakRepository;
    private final DailyAiReportRepository dailyAiReportRepository;
    private final DailyReportClient dailyReportClient;
    private final Clock clock;

    @Autowired
    public DailyReportApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            WeightGoalRepository weightGoalRepository,
            WeightEntryRepository weightEntryRepository,
            FoodEntryRepository foodEntryRepository,
            FoodItemRepository foodItemRepository,
            DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService,
            DailyNutritionSnapshotRepository dailyNutritionSnapshotRepository,
            StreakRepository streakRepository,
            DailyAiReportRepository dailyAiReportRepository,
            DailyReportClient dailyReportClient
    ) {
        this(
                currentUserApplicationService,
                userProfileRepository,
                weightGoalRepository,
                weightEntryRepository,
                foodEntryRepository,
                foodItemRepository,
                dailyNutritionSnapshotApplicationService,
                dailyNutritionSnapshotRepository,
                streakRepository,
                dailyAiReportRepository,
                dailyReportClient,
                Clock.systemUTC());
    }

    DailyReportApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            WeightGoalRepository weightGoalRepository,
            WeightEntryRepository weightEntryRepository,
            FoodEntryRepository foodEntryRepository,
            FoodItemRepository foodItemRepository,
            DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService,
            DailyNutritionSnapshotRepository dailyNutritionSnapshotRepository,
            StreakRepository streakRepository,
            DailyAiReportRepository dailyAiReportRepository,
            DailyReportClient dailyReportClient,
            Clock clock
    ) {
        this.currentUserApplicationService = currentUserApplicationService;
        this.userProfileRepository = userProfileRepository;
        this.weightGoalRepository = weightGoalRepository;
        this.weightEntryRepository = weightEntryRepository;
        this.foodEntryRepository = foodEntryRepository;
        this.foodItemRepository = foodItemRepository;
        this.dailyNutritionSnapshotApplicationService = dailyNutritionSnapshotApplicationService;
        this.dailyNutritionSnapshotRepository = dailyNutritionSnapshotRepository;
        this.streakRepository = streakRepository;
        this.dailyAiReportRepository = dailyAiReportRepository;
        this.dailyReportClient = dailyReportClient;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public DailyReportResponse getDailyReport(UUID userId, LocalDate date) {
        currentUserApplicationService.requireActiveUser(userId);
        if (date == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "date 不能为空");
        }
        return dailyAiReportRepository.findByUserIdAndReportDate(userId, date)
                .map(this::toResponse)
                .orElse(null);
    }

    @Transactional
    public DailyReportResponse generateDailyReport(UUID userId, GenerateDailyReportRequest request) {
        currentUserApplicationService.requireActiveUser(userId);
        UserProfileEntity profile = requireProfile(userId);
        LocalDate reportDate = resolveReportDate(request == null ? null : request.date(), profile);

        List<FoodEntryEntity> foodEntries = confirmedFoodEntries(userId, reportDate);
        WeightEntryEntity weightEntry = weightEntryRepository.findByUserIdAndRecordDate(userId, reportDate)
                .orElse(null);
        if (foodEntries.isEmpty() && weightEntry == null) {
            throw new BusinessException(ErrorCode.CONFLICT, "当天没有可用于生成日报的记录");
        }

        DailyNutritionSnapshotResponse snapshot = refreshSnapshot(userId, reportDate, profile, weightEntry);
        DailyNutritionSnapshotEntity snapshotEntity = dailyNutritionSnapshotRepository.findByUserIdAndDate(
                        userId,
                        reportDate)
                .orElseThrow(() -> new BusinessException(ErrorCode.INTERNAL_SERVER_ERROR, "日报快照生成失败"));
        DailyAiReportEntity report = dailyAiReportRepository.findByUserIdAndReportDate(userId, reportDate)
                .orElseGet(DailyAiReportEntity::new);
        report.setUserId(userId);
        report.setReportDate(reportDate);
        report.setSnapshotId(snapshotEntity.getId());
        report.setStatus(DailyReportStatus.PENDING.value());

        DailyReportInput input = buildInput(userId, reportDate, profile, snapshot, foodEntries, weightEntry);
        try {
            applySuccess(report, dailyReportClient.generateDailyReport(input));
        } catch (AiProviderException exception) {
            applyFailure(report, exception.providerErrorCode(), safeErrorMessage(exception.getMessage()));
        } catch (RuntimeException exception) {
            log.warn("AI 日报生成失败 userId={}, reportDate={}, error={}",
                    userId,
                    reportDate,
                    exception.getClass().getName());
            applyFailure(report, "ai_provider_error", ErrorCode.AI_SERVICE_ERROR.message());
        }

        return toResponse(dailyAiReportRepository.save(report));
    }

    @Transactional
    public DailyReportResponse markViewed(UUID userId, UUID reportId) {
        currentUserApplicationService.requireActiveUser(userId);
        DailyAiReportEntity report = dailyAiReportRepository.findById(reportId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND));
        if (!report.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        DailyReportStatus status = DailyReportStatus.fromValue(report.getStatus());
        if (status != DailyReportStatus.GENERATED && status != DailyReportStatus.VIEWED) {
            throw new BusinessException(ErrorCode.CONFLICT, "当前日报状态不可标记为已查看");
        }
        if (status == DailyReportStatus.GENERATED) {
            report.setStatus(DailyReportStatus.VIEWED.value());
            report.setViewedAt(Instant.now(clock));
        } else if (report.getViewedAt() == null) {
            report.setViewedAt(Instant.now(clock));
        }
        return toResponse(dailyAiReportRepository.save(report));
    }

    private DailyReportInput buildInput(
            UUID userId,
            LocalDate reportDate,
            UserProfileEntity profile,
            DailyNutritionSnapshotResponse snapshot,
            List<FoodEntryEntity> foodEntries,
            WeightEntryEntity weightEntry
    ) {
        return new DailyReportInput(
                userId,
                reportDate,
                new DailyReportProfileInput(
                        profile.getGender(),
                        profile.getAge(),
                        profile.getHeightCm(),
                        profile.getCurrentWeightKg(),
                        profile.getTargetWeightKg(),
                        profile.getActivityLevel(),
                        profile.getDailyCalorieTargetKcal()),
                activeGoal(userId),
                new DailyReportSnapshotInput(
                        snapshot.date(),
                        snapshot.calorieTargetKcal(),
                        snapshot.caloriesKcal(),
                        snapshot.remainingCaloriesKcal(),
                        snapshot.proteinG(),
                        snapshot.fatG(),
                        snapshot.carbsG(),
                        snapshot.foodEntryCount(),
                        snapshot.weightKg()),
                foodEntries.stream().map(this::toFoodEntryInput).toList(),
                weightEntry == null ? null : new DailyReportWeightEntryInput(
                        weightEntry.getRecordDate(),
                        weightEntry.getWeightKg()),
                streakInput(userId));
    }

    private DailyReportGoalInput activeGoal(UUID userId) {
        return weightGoalRepository.findFirstByUserIdAndStatusOrderByCreatedAtDesc(
                        userId,
                        WeightGoalStatus.ACTIVE.value())
                .map(goal -> new DailyReportGoalInput(
                        goal.getStartWeightKg(),
                        goal.getTargetWeightKg(),
                        goal.getTargetDate(),
                        goal.getDailyCalorieTargetKcal()))
                .orElse(null);
    }

    private DailyReportStreakInput streakInput(UUID userId) {
        return streakRepository.findByUserId(userId)
                .map(streak -> new DailyReportStreakInput(
                        streak.getCurrentDays(),
                        streak.getLongestDays(),
                        streak.getLastActiveDate()))
                .orElseGet(() -> new DailyReportStreakInput(0, 0, null));
    }

    private DailyReportFoodEntryInput toFoodEntryInput(FoodEntryEntity entry) {
        return new DailyReportFoodEntryInput(
                entry.getMealDate(),
                entry.getMealType(),
                entry.getTotalCaloriesKcal(),
                foodItemRepository.findByFoodEntryIdOrderBySortOrderAsc(entry.getId())
                        .stream()
                        .map(this::toFoodItemInput)
                        .toList());
    }

    private DailyReportFoodItemInput toFoodItemInput(FoodItemEntity item) {
        return new DailyReportFoodItemInput(
                item.getName(),
                item.getQuantityText(),
                item.getWeightG(),
                item.getCaloriesKcal(),
                item.getProteinG(),
                item.getFatG(),
                item.getCarbsG());
    }

    private DailyNutritionSnapshotResponse refreshSnapshot(
            UUID userId,
            LocalDate reportDate,
            UserProfileEntity profile,
            WeightEntryEntity weightEntry
    ) {
        DailyNutritionSnapshotResponse snapshot = dailyNutritionSnapshotApplicationService.recalculateDietTotals(
                userId,
                reportDate,
                profile.getDailyCalorieTargetKcal());
        if (weightEntry != null) {
            snapshot = dailyNutritionSnapshotApplicationService.updateWeight(
                    userId,
                    reportDate,
                    profile.getDailyCalorieTargetKcal(),
                    weightEntry.getWeightKg());
        }
        return snapshot;
    }

    private void applySuccess(DailyAiReportEntity report, DailyReportResult result) {
        report.setStatus(DailyReportStatus.GENERATED.value());
        report.setScore(Math.max(0, Math.min(100, result.score())));
        report.setSummary(trimToNull(result.summary()));
        report.setProblem(trimToNull(result.problem()));
        report.setSuggestion(trimToNull(result.suggestion()));
        report.setRawOutput(result.rawOutput());
        report.setErrorCode(null);
        report.setErrorMessage(null);
        report.setGeneratedAt(Instant.now(clock));
        report.setViewedAt(null);
    }

    private void applyFailure(DailyAiReportEntity report, String errorCode, String errorMessage) {
        String safeErrorCode = StringUtils.hasText(errorCode) ? errorCode : "ai_provider_error";
        report.setStatus(DailyReportStatus.FAILED.value());
        report.setScore(null);
        report.setSummary(null);
        report.setProblem(null);
        report.setSuggestion(null);
        report.setRawOutput(Map.of(
                "errorCode", safeErrorCode,
                "errorMessage", errorMessage));
        report.setErrorCode(safeErrorCode);
        report.setErrorMessage(errorMessage);
        report.setGeneratedAt(null);
        report.setViewedAt(null);
    }

    private List<FoodEntryEntity> confirmedFoodEntries(UUID userId, LocalDate reportDate) {
        return foodEntryRepository.findByUserIdAndMealDateAndStatusOrderByCreatedAtAsc(
                userId,
                reportDate,
                FoodEntryStatus.CONFIRMED.value());
    }

    private LocalDate resolveReportDate(LocalDate requestDate, UserProfileEntity profile) {
        LocalDate today = LocalDate.now(clock.withZone(zoneId(profile)));
        LocalDate resolvedDate = requestDate == null ? today : requestDate;
        if (resolvedDate.isAfter(today)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "日报日期不能晚于今天");
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

    private DailyReportResponse toResponse(DailyAiReportEntity report) {
        return new DailyReportResponse(
                report.getId(),
                report.getReportDate(),
                report.getScore(),
                report.getSummary(),
                report.getProblem(),
                report.getSuggestion(),
                DailyReportStatus.fromValue(report.getStatus()),
                report.getGeneratedAt(),
                report.getViewedAt());
    }

    private String trimToNull(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        return value.trim();
    }

    private String safeErrorMessage(String message) {
        return StringUtils.hasText(message) ? message : ErrorCode.AI_SERVICE_ERROR.message();
    }
}
