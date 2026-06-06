package com.leanmate.stats.application;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.stats.dto.FoodEntrySummaryResponse;
import com.leanmate.stats.dto.TodayHomeResponse;
import com.leanmate.stats.repository.DailyAiReportSummaryRepository;
import com.leanmate.stats.repository.FoodEntrySummaryRepository;
import com.leanmate.stats.repository.FoodEntrySummaryRow;
import com.leanmate.stats.repository.StreakRepository;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.weight.repository.WeightEntryRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.DateTimeException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class HomeApplicationService {

    private static final BigDecimal ZERO = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
    private static final String ITEM_NAME_DELIMITER = "\u001F";

    private final CurrentUserApplicationService currentUserApplicationService;
    private final UserProfileRepository userProfileRepository;
    private final WeightEntryRepository weightEntryRepository;
    private final DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService;
    private final FoodEntrySummaryRepository foodEntrySummaryRepository;
    private final DailyAiReportSummaryRepository dailyAiReportSummaryRepository;
    private final StreakRepository streakRepository;
    private final Clock clock;

    @Autowired
    public HomeApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            WeightEntryRepository weightEntryRepository,
            DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService,
            FoodEntrySummaryRepository foodEntrySummaryRepository,
            DailyAiReportSummaryRepository dailyAiReportSummaryRepository,
            StreakRepository streakRepository
    ) {
        this(
                currentUserApplicationService,
                userProfileRepository,
                weightEntryRepository,
                dailyNutritionSnapshotApplicationService,
                foodEntrySummaryRepository,
                dailyAiReportSummaryRepository,
                streakRepository,
                Clock.systemUTC());
    }

    HomeApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            WeightEntryRepository weightEntryRepository,
            DailyNutritionSnapshotApplicationService dailyNutritionSnapshotApplicationService,
            FoodEntrySummaryRepository foodEntrySummaryRepository,
            DailyAiReportSummaryRepository dailyAiReportSummaryRepository,
            StreakRepository streakRepository,
            Clock clock
    ) {
        this.currentUserApplicationService = currentUserApplicationService;
        this.userProfileRepository = userProfileRepository;
        this.weightEntryRepository = weightEntryRepository;
        this.dailyNutritionSnapshotApplicationService = dailyNutritionSnapshotApplicationService;
        this.foodEntrySummaryRepository = foodEntrySummaryRepository;
        this.dailyAiReportSummaryRepository = dailyAiReportSummaryRepository;
        this.streakRepository = streakRepository;
        this.clock = clock;
    }

    @Transactional
    public TodayHomeResponse getToday(UUID userId, LocalDate requestDate) {
        currentUserApplicationService.requireActiveUser(userId);
        return userProfileRepository.findByUserId(userId)
                .map(profile -> buildCompletedProfileHome(userId, profile, requestDate))
                .orElseGet(() -> buildIncompleteProfileHome(requestDate));
    }

    private TodayHomeResponse buildCompletedProfileHome(
            UUID userId,
            UserProfileEntity profile,
            LocalDate requestDate
    ) {
        LocalDate date = resolveDate(requestDate, zoneId(profile));
        DailyNutritionSnapshotResponse snapshot = dailyNutritionSnapshotApplicationService.getOrCreateForHome(
                userId,
                date,
                profile.getDailyCalorieTargetKcal());
        BigDecimal currentWeightKg = weightEntryRepository
                .findFirstByUserIdAndRecordDateLessThanEqualOrderByRecordDateDesc(userId, date)
                .map(entry -> entry.getWeightKg())
                .orElse(profile.getCurrentWeightKg());
        List<FoodEntrySummaryResponse> foodEntries = foodEntrySummaryRepository
                .findConfirmedSummaries(userId, date)
                .stream()
                .map(this::toFoodEntrySummary)
                .toList();
        int streakDays = streakRepository.findByUserId(userId)
                .map(streak -> streak.getCurrentDays())
                .orElse(0);
        String reportSummary = dailyAiReportSummaryRepository
                .findGeneratedSummary(userId, date)
                .orElse(null);

        return new TodayHomeResponse(
                date,
                true,
                snapshot.calorieTargetKcal(),
                snapshot.caloriesKcal(),
                snapshot.remainingCaloriesKcal(),
                snapshot.proteinG(),
                snapshot.fatG(),
                snapshot.carbsG(),
                currentWeightKg,
                streakDays,
                reportSummary,
                foodEntries);
    }

    private TodayHomeResponse buildIncompleteProfileHome(LocalDate requestDate) {
        LocalDate date = resolveDate(requestDate, ZoneId.of("Asia/Shanghai"));
        return new TodayHomeResponse(
                date,
                false,
                0,
                0,
                0,
                ZERO,
                ZERO,
                ZERO,
                null,
                0,
                null,
                List.of());
    }

    private FoodEntrySummaryResponse toFoodEntrySummary(FoodEntrySummaryRow row) {
        return new FoodEntrySummaryResponse(
                row.getId(),
                row.getMealType(),
                row.getTotalCaloriesKcal(),
                parseItemNames(row.getItemNamesText()));
    }

    private List<String> parseItemNames(String itemNamesText) {
        if (itemNamesText == null || itemNamesText.isBlank()) {
            return List.of();
        }
        return Arrays.stream(itemNamesText.split(ITEM_NAME_DELIMITER))
                .filter(name -> !name.isBlank())
                .toList();
    }

    private LocalDate resolveDate(LocalDate requestDate, ZoneId zoneId) {
        if (requestDate != null) {
            return requestDate;
        }
        return LocalDate.now(clock.withZone(zoneId));
    }

    private ZoneId zoneId(UserProfileEntity profile) {
        try {
            return ZoneId.of(profile.getTimezone());
        } catch (DateTimeException exception) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "timezone 无效");
        }
    }
}
