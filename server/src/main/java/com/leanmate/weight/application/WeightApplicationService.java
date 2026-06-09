package com.leanmate.weight.application;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.stats.application.DailyNutritionSnapshotApplicationService;
import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.domain.WeightGoalStatus;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.user.repository.WeightGoalEntity;
import com.leanmate.user.repository.WeightGoalRepository;
import com.leanmate.weight.dto.SaveWeightEntryRequest;
import com.leanmate.weight.dto.SyncLocalWeightEntryRequest;
import com.leanmate.weight.dto.WeightEntryResponse;
import com.leanmate.weight.dto.WeightEntrySaveResultResponse;
import com.leanmate.weight.dto.WeightTrendPointResponse;
import com.leanmate.weight.dto.WeightTrendResponse;
import com.leanmate.weight.domain.WeightTrendDirection;
import com.leanmate.weight.repository.WeightEntryEntity;
import com.leanmate.weight.repository.WeightEntryRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.DateTimeException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class WeightApplicationService {

    private static final long MAX_QUERY_DAYS = 180;

    private final CurrentUserApplicationService currentUserApplicationService;
    private final UserProfileRepository userProfileRepository;
    private final WeightGoalRepository weightGoalRepository;
    private final WeightEntryRepository weightEntryRepository;
    private final DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService;
    private final Clock clock;

    @Autowired
    public WeightApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            WeightGoalRepository weightGoalRepository,
            WeightEntryRepository weightEntryRepository,
            DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService
    ) {
        this(
                currentUserApplicationService,
                userProfileRepository,
                weightGoalRepository,
                weightEntryRepository,
                dailyNutritionSnapshotApplicationService,
                Clock.systemUTC());
    }

    WeightApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            WeightGoalRepository weightGoalRepository,
            WeightEntryRepository weightEntryRepository,
            DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService,
            Clock clock
    ) {
        this.currentUserApplicationService = currentUserApplicationService;
        this.userProfileRepository = userProfileRepository;
        this.weightGoalRepository = weightGoalRepository;
        this.weightEntryRepository = weightEntryRepository;
        this.dailyNutritionSnapshotApplicationService = dailyNutritionSnapshotApplicationService;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public List<WeightEntryResponse> listWeights(UUID userId, LocalDate startDate, LocalDate endDate) {
        currentUserApplicationService.requireActiveUser(userId);
        validateDateRange(startDate, endDate);
        return weightEntryRepository.findByUserIdAndRecordDateBetweenOrderByRecordDateAsc(userId, startDate, endDate)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public WeightEntrySaveResultResponse saveWeight(UUID userId, SaveWeightEntryRequest request) {
        currentUserApplicationService.requireActiveUser(userId);
        UserProfileEntity profile = requireProfile(userId);
        validateRecordDate(request.recordDate(), profile);

        WeightEntryEntity savedEntry = saveWeightEntry(
                userId,
                null,
                request.recordDate(),
                request.weightKg(),
                request.note(),
                true);
        DailyNutritionSnapshotResponse snapshot = dailyNutritionSnapshotApplicationService.updateWeight(
                userId,
                request.recordDate(),
                profile.getDailyCalorieTargetKcal(),
                savedEntry.getWeightKg());
        return new WeightEntrySaveResultResponse(toResponse(savedEntry), snapshot);
    }

    @Transactional(readOnly = true)
    public WeightTrendResponse getTrend(UUID userId, Integer days) {
        currentUserApplicationService.requireActiveUser(userId);
        UserProfileEntity profile = requireProfile(userId);
        int safeDays = days == null ? 30 : Math.min(Math.max(days, 7), (int) MAX_QUERY_DAYS);
        LocalDate today = LocalDate.now(clock.withZone(zoneId(profile)));
        LocalDate startDate = today.minusDays(safeDays - 1L);
        List<WeightEntryEntity> weights = weightEntryRepository
                .findByUserIdAndRecordDateBetweenOrderByRecordDateAsc(userId, startDate, today);
        return toTrendResponse(userId, safeDays, today, weights);
    }

    @Transactional
    public Optional<WeightEntryResponse> syncLocalWeight(
            UUID userId,
            UserProfileEntity profile,
            SyncLocalWeightEntryRequest request
    ) {
        validateSyncLocalWeight(request);
        validateRecordDate(request.recordDate(), profile);
        Optional<WeightEntryEntity> existingByClientLocalId = weightEntryRepository
                .findByUserIdAndClientLocalId(userId, request.clientLocalId());
        if (existingByClientLocalId.isPresent()) {
            return Optional.empty();
        }

        WeightEntryEntity existingByDate = weightEntryRepository
                .findByUserIdAndRecordDate(userId, request.recordDate())
                .orElse(null);
        if (existingByDate != null && existingByDate.getUpdatedAt() != null
                && existingByDate.getUpdatedAt().isAfter(request.updatedAt())) {
            return Optional.empty();
        }

        WeightEntryEntity savedEntry = saveWeightEntry(
                userId,
                request.clientLocalId(),
                request.recordDate(),
                request.weightKg(),
                request.note(),
                false);
        dailyNutritionSnapshotApplicationService.updateWeight(
                userId,
                request.recordDate(),
                profile.getDailyCalorieTargetKcal(),
                savedEntry.getWeightKg());
        return Optional.of(toResponse(savedEntry));
    }

    private void validateSyncLocalWeight(SyncLocalWeightEntryRequest request) {
        if (request == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "体重记录不能为空");
        }
        if (request.clientLocalId() == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "clientLocalId 不能为空");
        }
        if (request.recordDate() == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "recordDate 不能为空");
        }
        if (request.weightKg() == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "weightKg 不能为空");
        }
        if (request.updatedAt() == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "updatedAt 不能为空");
        }
    }

    private WeightEntryEntity saveWeightEntry(
            UUID userId,
            UUID clientLocalId,
            LocalDate recordDate,
            BigDecimal weightKg,
            String note,
            boolean preserveExistingClientLocalId
    ) {
        WeightEntryEntity entry = weightEntryRepository
                .findByUserIdAndRecordDate(userId, recordDate)
                .orElseGet(WeightEntryEntity::new);
        entry.setUserId(userId);
        entry.setRecordDate(recordDate);
        if (clientLocalId != null || !preserveExistingClientLocalId) {
            entry.setClientLocalId(clientLocalId);
        }
        entry.setWeightKg(scaleWeight(weightKg));
        entry.setNote(trimToNull(note));
        return weightEntryRepository.save(entry);
    }

    private WeightTrendResponse toTrendResponse(
            UUID userId,
            int days,
            LocalDate today,
            List<WeightEntryEntity> weights
    ) {
        BigDecimal targetWeightKg = weightGoalRepository
                .findFirstByUserIdAndStatusOrderByCreatedAtDesc(userId, WeightGoalStatus.ACTIVE.value())
                .map(WeightGoalEntity::getTargetWeightKg)
                .orElse(null);
        if (weights.isEmpty()) {
            return new WeightTrendResponse(days, targetWeightKg, null, null, null, WeightTrendDirection.FLAT, List.of());
        }
        BigDecimal startWeightKg = weights.get(0).getWeightKg();
        BigDecimal latestWeightKg = weights.get(weights.size() - 1).getWeightKg();
        BigDecimal changeKg = latestWeightKg.subtract(startWeightKg).setScale(2, RoundingMode.HALF_UP);
        return new WeightTrendResponse(
                days,
                targetWeightKg,
                startWeightKg,
                latestWeightKg,
                changeKg,
                trendDirection(changeKg),
                weights.stream()
                        .map(entry -> new WeightTrendPointResponse(
                                entry.getRecordDate(),
                                entry.getWeightKg(),
                                entry.getRecordDate().equals(today)))
                        .toList());
    }

    private void validateDateRange(LocalDate startDate, LocalDate endDate) {
        if (startDate == null || endDate == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "日期范围不能为空");
        }
        if (startDate.isAfter(endDate)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "startDate 不能晚于 endDate");
        }
        if (ChronoUnit.DAYS.between(startDate, endDate) > MAX_QUERY_DAYS) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "查询区间不能超过 180 天");
        }
    }

    private void validateRecordDate(LocalDate recordDate, UserProfileEntity profile) {
        LocalDate today = LocalDate.now(clock.withZone(zoneId(profile)));
        if (recordDate.isAfter(today)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "体重记录日期不能晚于今天");
        }
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

    private WeightEntryResponse toResponse(WeightEntryEntity entry) {
        return new WeightEntryResponse(
                entry.getId(),
                entry.getClientLocalId(),
                entry.getRecordDate(),
                entry.getWeightKg(),
                entry.getNote(),
                entry.getCreatedAt());
    }

    private BigDecimal scaleWeight(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }

    private WeightTrendDirection trendDirection(BigDecimal changeKg) {
        if (changeKg.compareTo(new BigDecimal("0.05")) > 0) {
            return WeightTrendDirection.INCREASING;
        }
        if (changeKg.compareTo(new BigDecimal("-0.05")) < 0) {
            return WeightTrendDirection.DECREASING;
        }
        return WeightTrendDirection.FLAT;
    }

    private String trimToNull(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        return value.trim();
    }
}
