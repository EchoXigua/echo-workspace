package com.leanmate.user.application;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.user.domain.ActivityLevel;
import com.leanmate.user.domain.Gender;
import com.leanmate.user.domain.ProfileCalculationResult;
import com.leanmate.user.domain.ProfileCalculator;
import com.leanmate.user.domain.WeightGoalStatus;
import com.leanmate.user.dto.CalorieTargetSuggestionResponse;
import com.leanmate.user.dto.ProfilePayload;
import com.leanmate.user.dto.SaveUserProfileRequest;
import com.leanmate.user.dto.UserProfileResponse;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.user.repository.WeightGoalEntity;
import com.leanmate.user.repository.WeightGoalRepository;
import com.leanmate.weight.repository.WeightEntryEntity;
import com.leanmate.weight.repository.WeightEntryRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.DateTimeException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserProfileApplicationService {

    private static final int CALORIE_TARGET_ADJUSTMENT_KCAL = 100;
    private static final long CALORIE_TARGET_TREND_DAYS = 14;
    private static final int MIN_WEIGHT_RECORDS_PER_WINDOW = 3;
    private static final BigDecimal KCAL_PER_KG = new BigDecimal("7700");
    private static final BigDecimal SLOW_LOSS_TOLERANCE_KG = new BigDecimal("0.20");
    private static final BigDecimal FAST_LOSS_TOLERANCE_KG = new BigDecimal("0.35");

    private final CurrentUserApplicationService currentUserApplicationService;
    private final UserProfileRepository userProfileRepository;
    private final WeightGoalRepository weightGoalRepository;
    private final WeightEntryRepository weightEntryRepository;
    private final ProfileCalculator profileCalculator;
    private final Clock clock;

    @Autowired
    public UserProfileApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            WeightGoalRepository weightGoalRepository,
            WeightEntryRepository weightEntryRepository,
            ProfileCalculator profileCalculator
    ) {
        this(
                currentUserApplicationService,
                userProfileRepository,
                weightGoalRepository,
                weightEntryRepository,
                profileCalculator,
                Clock.systemUTC());
    }

    UserProfileApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            WeightGoalRepository weightGoalRepository,
            WeightEntryRepository weightEntryRepository,
            ProfileCalculator profileCalculator,
            Clock clock
    ) {
        this.currentUserApplicationService = currentUserApplicationService;
        this.userProfileRepository = userProfileRepository;
        this.weightGoalRepository = weightGoalRepository;
        this.weightEntryRepository = weightEntryRepository;
        this.profileCalculator = profileCalculator;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public ProfilePayload getProfile(UUID userId) {
        currentUserApplicationService.requireActiveUser(userId);
        return userProfileRepository.findByUserId(userId)
                .map(profile -> new ProfilePayload(true, toResponse(profile)))
                .orElseGet(() -> new ProfilePayload(false, null));
    }

    @Transactional
    public ProfilePayload saveProfile(UUID userId, SaveUserProfileRequest request) {
        currentUserApplicationService.requireActiveUser(userId);
        ZoneId zoneId = parseTimezone(request.timezone());
        LocalDate today = LocalDate.now(zoneId);
        if (request.targetDate() != null && !request.targetDate().isAfter(today)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "目标日期必须晚于今天");
        }

        ProfileCalculationResult calculation = profileCalculator.calculate(
                request.gender(),
                request.age(),
                request.heightCm(),
                request.currentWeightKg(),
                request.targetWeightKg(),
                request.activityLevel(),
                request.targetDate(),
                today);

        UserProfileEntity profile = userProfileRepository.findByUserId(userId)
                .orElseGet(UserProfileEntity::new);
        profile.setUserId(userId);
        profile.setGender(request.gender().value());
        profile.setAge(request.age());
        profile.setHeightCm(scaleWeightOrHeight(request.heightCm()));
        profile.setCurrentWeightKg(scaleWeightOrHeight(request.currentWeightKg()));
        profile.setTargetWeightKg(scaleWeightOrHeight(request.targetWeightKg()));
        profile.setActivityLevel(request.activityLevel().value());
        profile.setTimezone(request.timezone());
        profile.setBmi(calculation.bmi());
        profile.setBmrKcal(calculation.bmrKcal());
        profile.setDailyCalorieTargetKcal(calculation.dailyCalorieTargetKcal());
        UserProfileEntity savedProfile = userProfileRepository.save(profile);

        saveActiveWeightGoal(userId, request, calculation);
        return new ProfilePayload(true, toResponse(savedProfile, request.targetDate()));
    }

    @Transactional(readOnly = true)
    public CalorieTargetSuggestionResponse getCalorieTargetSuggestion(UUID userId) {
        currentUserApplicationService.requireActiveUser(userId);
        UserProfileEntity profile = userProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.BAD_REQUEST, "请先完成用户档案"));

        LocalDate today = LocalDate.now(clock.withZone(zoneId(profile)));
        LocalDate startDate = today.minusDays(CALORIE_TARGET_TREND_DAYS - 1);
        List<WeightEntryEntity> weights = weightEntryRepository
                .findByUserIdAndRecordDateBetweenOrderByRecordDateAsc(userId, startDate, today);

        LocalDate firstWindowEnd = today.minusDays(7);
        LocalDate secondWindowStart = today.minusDays(6);
        BigDecimal startAverage = averageWeight(weights, startDate, firstWindowEnd);
        BigDecimal endAverage = averageWeight(weights, secondWindowStart, today);
        if (startAverage == null || endAverage == null) {
            return noChange(
                    "insufficient_data",
                    profile,
                    "至少需要最近 14 天内前后两个时间窗口各 3 条体重记录",
                    null,
                    null,
                    null);
        }

        BigDecimal weeklyWeightChange = endAverage.subtract(startAverage).setScale(2, RoundingMode.HALF_UP);
        BigDecimal actualWeeklyLoss = weeklyWeightChange.negate();
        BigDecimal expectedWeeklyLoss = expectedWeeklyLoss(profile);
        if (expectedWeeklyLoss.compareTo(BigDecimal.ZERO) <= 0) {
            return noChange(
                    "not_applicable",
                    profile,
                    "当前目标不处于减脂热量缺口场景",
                    startAverage,
                    endAverage,
                    weeklyWeightChange);
        }

        int currentTarget = profile.getDailyCalorieTargetKcal();
        if (actualWeeklyLoss.compareTo(expectedWeeklyLoss.subtract(SLOW_LOSS_TOLERANCE_KG)) < 0) {
            int suggestedTarget = Math.max(
                    currentTarget - CALORIE_TARGET_ADJUSTMENT_KCAL,
                    Gender.fromValue(profile.getGender()).calorieFloorKcal());
            if (suggestedTarget == currentTarget) {
                return noChange(
                        "at_safety_floor",
                        profile,
                        "当前目标已达到安全下限，不建议继续下调",
                        startAverage,
                        endAverage,
                        weeklyWeightChange);
            }
            return suggestion(
                    "suggest_lower",
                    profile,
                    suggestedTarget,
                    "过去 14 天体重下降慢于预期，建议小幅下调每日目标热量",
                    startAverage,
                    endAverage,
                    weeklyWeightChange);
        }

        if (actualWeeklyLoss.compareTo(expectedWeeklyLoss.add(FAST_LOSS_TOLERANCE_KG)) > 0) {
            int suggestedTarget = currentTarget + CALORIE_TARGET_ADJUSTMENT_KCAL;
            return suggestion(
                    "suggest_higher",
                    profile,
                    suggestedTarget,
                    "过去 14 天体重下降快于预期，建议小幅上调每日目标热量",
                    startAverage,
                    endAverage,
                    weeklyWeightChange);
        }

        return noChange(
                "on_track",
                profile,
                "过去 14 天体重变化接近当前目标预期，暂不建议调整",
                startAverage,
                endAverage,
                weeklyWeightChange);
    }

    private void saveActiveWeightGoal(
            UUID userId,
            SaveUserProfileRequest request,
            ProfileCalculationResult calculation
    ) {
        WeightGoalEntity goal = weightGoalRepository
                .findFirstByUserIdAndStatusOrderByCreatedAtDesc(userId, WeightGoalStatus.ACTIVE.value())
                .orElseGet(WeightGoalEntity::new);
        goal.setUserId(userId);
        goal.setStartWeightKg(scaleWeightOrHeight(request.currentWeightKg()));
        goal.setTargetWeightKg(scaleWeightOrHeight(request.targetWeightKg()));
        goal.setTargetDate(request.targetDate());
        goal.setDailyCalorieTargetKcal(calculation.dailyCalorieTargetKcal());
        goal.setStatus(WeightGoalStatus.ACTIVE.value());
        weightGoalRepository.save(goal);
    }

    private UserProfileResponse toResponse(UserProfileEntity profile) {
        LocalDate targetDate = weightGoalRepository
                .findFirstByUserIdAndStatusOrderByCreatedAtDesc(profile.getUserId(), WeightGoalStatus.ACTIVE.value())
                .map(WeightGoalEntity::getTargetDate)
                .orElse(null);
        return toResponse(profile, targetDate);
    }

    private UserProfileResponse toResponse(UserProfileEntity profile, LocalDate targetDate) {
        return new UserProfileResponse(
                Gender.fromValue(profile.getGender()),
                profile.getAge(),
                profile.getHeightCm(),
                profile.getCurrentWeightKg(),
                profile.getTargetWeightKg(),
                ActivityLevel.fromValue(profile.getActivityLevel()),
                profile.getTimezone(),
                targetDate,
                profile.getBmi(),
                profile.getBmrKcal(),
                profile.getDailyCalorieTargetKcal());
    }

    private ZoneId parseTimezone(String timezone) {
        try {
            return ZoneId.of(timezone);
        } catch (DateTimeException exception) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "timezone 无效");
        }
    }

    private ZoneId zoneId(UserProfileEntity profile) {
        try {
            return ZoneId.of(profile.getTimezone());
        } catch (DateTimeException exception) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "timezone 无效");
        }
    }

    private BigDecimal averageWeight(List<WeightEntryEntity> weights, LocalDate startDate, LocalDate endDate) {
        List<BigDecimal> windowWeights = weights.stream()
                .filter(entry -> !entry.getRecordDate().isBefore(startDate) && !entry.getRecordDate().isAfter(endDate))
                .map(WeightEntryEntity::getWeightKg)
                .toList();
        if (windowWeights.size() < MIN_WEIGHT_RECORDS_PER_WINDOW) {
            return null;
        }

        BigDecimal sum = windowWeights.stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        return sum.divide(new BigDecimal(windowWeights.size()), 2, RoundingMode.HALF_UP);
    }

    private BigDecimal expectedWeeklyLoss(UserProfileEntity profile) {
        if (profile.getTargetWeightKg().compareTo(profile.getCurrentWeightKg()) >= 0) {
            return BigDecimal.ZERO;
        }

        double tdee = profile.getBmrKcal() * ActivityLevel.fromValue(profile.getActivityLevel()).multiplier();
        BigDecimal dailyDeficit = BigDecimal.valueOf(tdee)
                .subtract(new BigDecimal(profile.getDailyCalorieTargetKcal()));
        if (dailyDeficit.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }

        return dailyDeficit.multiply(new BigDecimal("7"))
                .divide(KCAL_PER_KG, 2, RoundingMode.HALF_UP);
    }

    private CalorieTargetSuggestionResponse noChange(
            String status,
            UserProfileEntity profile,
            String reason,
            BigDecimal startAverageWeightKg,
            BigDecimal endAverageWeightKg,
            BigDecimal weeklyWeightChangeKg
    ) {
        return new CalorieTargetSuggestionResponse(
                status,
                profile.getDailyCalorieTargetKcal(),
                profile.getDailyCalorieTargetKcal(),
                0,
                reason,
                false,
                (int) CALORIE_TARGET_TREND_DAYS,
                startAverageWeightKg,
                endAverageWeightKg,
                weeklyWeightChangeKg);
    }

    private CalorieTargetSuggestionResponse suggestion(
            String status,
            UserProfileEntity profile,
            int suggestedTargetKcal,
            String reason,
            BigDecimal startAverageWeightKg,
            BigDecimal endAverageWeightKg,
            BigDecimal weeklyWeightChangeKg
    ) {
        int currentTargetKcal = profile.getDailyCalorieTargetKcal();
        return new CalorieTargetSuggestionResponse(
                status,
                currentTargetKcal,
                suggestedTargetKcal,
                suggestedTargetKcal - currentTargetKcal,
                reason,
                true,
                (int) CALORIE_TARGET_TREND_DAYS,
                startAverageWeightKg,
                endAverageWeightKg,
                weeklyWeightChangeKg);
    }

    private BigDecimal scaleWeightOrHeight(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }
}
