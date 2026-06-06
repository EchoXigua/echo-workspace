package com.leanmate.weight.application;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.stats.application.DailyNutritionSnapshotApplicationService;
import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.weight.dto.SaveWeightEntryRequest;
import com.leanmate.weight.dto.WeightEntryResponse;
import com.leanmate.weight.dto.WeightEntrySaveResultResponse;
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
    private final WeightEntryRepository weightEntryRepository;
    private final DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService;
    private final Clock clock;

    @Autowired
    public WeightApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            WeightEntryRepository weightEntryRepository,
            DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService
    ) {
        this(
                currentUserApplicationService,
                userProfileRepository,
                weightEntryRepository,
                dailyNutritionSnapshotApplicationService,
                Clock.systemUTC());
    }

    WeightApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            WeightEntryRepository weightEntryRepository,
            DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService,
            Clock clock
    ) {
        this.currentUserApplicationService = currentUserApplicationService;
        this.userProfileRepository = userProfileRepository;
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

        WeightEntryEntity entry = weightEntryRepository
                .findByUserIdAndRecordDate(userId, request.recordDate())
                .orElseGet(WeightEntryEntity::new);
        entry.setUserId(userId);
        entry.setRecordDate(request.recordDate());
        entry.setWeightKg(scaleWeight(request.weightKg()));
        entry.setNote(trimToNull(request.note()));
        WeightEntryEntity savedEntry = weightEntryRepository.save(entry);

        DailyNutritionSnapshotResponse snapshot = dailyNutritionSnapshotApplicationService.updateWeight(
                userId,
                request.recordDate(),
                profile.getDailyCalorieTargetKcal(),
                savedEntry.getWeightKg());
        return new WeightEntrySaveResultResponse(toResponse(savedEntry), snapshot);
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
                entry.getRecordDate(),
                entry.getWeightKg(),
                entry.getNote(),
                entry.getCreatedAt());
    }

    private BigDecimal scaleWeight(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }

    private String trimToNull(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        return value.trim();
    }
}
