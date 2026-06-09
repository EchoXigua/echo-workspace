package com.leanmate.retention.application;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.diet.domain.FoodEntryStatus;
import com.leanmate.diet.repository.FoodEntryRepository;
import com.leanmate.retention.domain.RetentionNoticeStatus;
import com.leanmate.retention.dto.RetentionNoticeResponse;
import com.leanmate.retention.dto.StreakMilestoneResponse;
import com.leanmate.retention.dto.StreakResponse;
import com.leanmate.retention.repository.AchievementEntity;
import com.leanmate.retention.repository.AchievementRepository;
import com.leanmate.retention.repository.RetentionNoticeEntity;
import com.leanmate.retention.repository.RetentionNoticeRepository;
import com.leanmate.stats.repository.StreakEntity;
import com.leanmate.stats.repository.StreakRepository;
import com.leanmate.user.application.CurrentUserApplicationService;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.weight.repository.WeightEntryRepository;
import java.time.Clock;
import java.time.DateTimeException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RetentionApplicationService {

    private static final ZoneId DEFAULT_ZONE_ID = ZoneId.of("Asia/Shanghai");
    private static final String STREAK_NOTICE_TYPE = "streak";
    private static final List<Integer> MILESTONE_DAYS = List.of(3, 7, 12, 30, 100);

    private final CurrentUserApplicationService currentUserApplicationService;
    private final UserProfileRepository userProfileRepository;
    private final FoodEntryRepository foodEntryRepository;
    private final WeightEntryRepository weightEntryRepository;
    private final StreakRepository streakRepository;
    private final AchievementRepository achievementRepository;
    private final RetentionNoticeRepository retentionNoticeRepository;
    private final Clock clock;

    @Autowired
    public RetentionApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            FoodEntryRepository foodEntryRepository,
            WeightEntryRepository weightEntryRepository,
            StreakRepository streakRepository,
            AchievementRepository achievementRepository,
            RetentionNoticeRepository retentionNoticeRepository
    ) {
        this(
                currentUserApplicationService,
                userProfileRepository,
                foodEntryRepository,
                weightEntryRepository,
                streakRepository,
                achievementRepository,
                retentionNoticeRepository,
                Clock.systemUTC());
    }

    RetentionApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            FoodEntryRepository foodEntryRepository,
            WeightEntryRepository weightEntryRepository,
            StreakRepository streakRepository,
            AchievementRepository achievementRepository,
            RetentionNoticeRepository retentionNoticeRepository,
            Clock clock
    ) {
        this.currentUserApplicationService = currentUserApplicationService;
        this.userProfileRepository = userProfileRepository;
        this.foodEntryRepository = foodEntryRepository;
        this.weightEntryRepository = weightEntryRepository;
        this.streakRepository = streakRepository;
        this.achievementRepository = achievementRepository;
        this.retentionNoticeRepository = retentionNoticeRepository;
        this.clock = clock;
    }

    @Transactional
    public StreakResponse getStreak(UUID userId) {
        currentUserApplicationService.requireActiveUser(userId);
        LocalDate today = LocalDate.now(clock.withZone(zoneId(userId)));
        StreakCalculation calculation = calculate(activeDates(userId, today), today);
        saveStreak(userId, calculation);
        Map<String, AchievementEntity> achievements = saveReachedMilestones(userId, calculation.longestDays());
        return toResponse(calculation, achievements);
    }

    @Transactional
    public List<RetentionNoticeResponse> listPendingNotices(UUID userId) {
        currentUserApplicationService.requireActiveUser(userId);
        getStreak(userId);
        return retentionNoticeRepository
                .findByUserIdAndStatusOrderByTriggeredAtAsc(userId, RetentionNoticeStatus.PENDING.value())
                .stream()
                .map(this::toNoticeResponse)
                .toList();
    }

    @Transactional
    public void dismissNotice(UUID userId, UUID noticeId) {
        currentUserApplicationService.requireActiveUser(userId);
        RetentionNoticeEntity notice = retentionNoticeRepository.findById(noticeId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND));
        if (!notice.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        notice.setStatus(RetentionNoticeStatus.DISMISSED.value());
        notice.setDismissedAt(Instant.now(clock));
        retentionNoticeRepository.save(notice);
    }

    private Set<LocalDate> activeDates(UUID userId, LocalDate today) {
        Set<LocalDate> activeDates = new TreeSet<>();
        activeDates.addAll(foodEntryRepository.findDistinctMealDatesOnOrBefore(
                userId,
                FoodEntryStatus.CONFIRMED.value(),
                today));
        activeDates.addAll(weightEntryRepository.findDistinctRecordDatesOnOrBefore(userId, today));
        return activeDates;
    }

    private StreakCalculation calculate(Set<LocalDate> activeDates, LocalDate today) {
        if (activeDates.isEmpty()) {
            return new StreakCalculation(0, 0, null);
        }

        int longestDays = 0;
        int runDays = 0;
        LocalDate previousDate = null;
        for (LocalDate activeDate : activeDates) {
            if (previousDate == null || previousDate.plusDays(1).equals(activeDate)) {
                runDays++;
            } else {
                runDays = 1;
            }
            longestDays = Math.max(longestDays, runDays);
            previousDate = activeDate;
        }

        LocalDate lastActiveDate = activeDates.stream().max(Comparator.naturalOrder()).orElseThrow();
        int currentDays = currentDays(activeDates, today, lastActiveDate);
        return new StreakCalculation(currentDays, longestDays, lastActiveDate);
    }

    private int currentDays(Set<LocalDate> activeDates, LocalDate today, LocalDate lastActiveDate) {
        if (lastActiveDate.isBefore(today.minusDays(1))) {
            return 0;
        }

        int currentDays = 0;
        LocalDate cursor = lastActiveDate;
        while (activeDates.contains(cursor)) {
            currentDays++;
            cursor = cursor.minusDays(1);
        }
        return currentDays;
    }

    private void saveStreak(UUID userId, StreakCalculation calculation) {
        StreakEntity streak = streakRepository.findByUserId(userId).orElseGet(StreakEntity::new);
        streak.setUserId(userId);
        streak.setCurrentDays(calculation.currentDays());
        streak.setLongestDays(calculation.longestDays());
        streak.setLastActiveDate(calculation.lastActiveDate());
        streakRepository.save(streak);
    }

    private Map<String, AchievementEntity> saveReachedMilestones(UUID userId, int longestDays) {
        List<String> milestoneTypes = MILESTONE_DAYS.stream().map(this::milestoneType).toList();
        Map<String, AchievementEntity> achievements = achievementRepository
                .findByUserIdAndTypeIn(userId, milestoneTypes)
                .stream()
                .collect(Collectors.toMap(
                        AchievementEntity::getType,
                        Function.identity(),
                        (left, right) -> left,
                        LinkedHashMap::new));

        List<AchievementEntity> newAchievements = new ArrayList<>();
        Instant now = Instant.now(clock);
        for (Integer days : MILESTONE_DAYS) {
            String type = milestoneType(days);
            if (longestDays >= days && !achievements.containsKey(type)) {
                AchievementEntity achievement = new AchievementEntity();
                achievement.setUserId(userId);
                achievement.setType(type);
                achievement.setAchievedAt(now);
                newAchievements.add(achievement);
                ensureStreakNotice(userId, days, now);
            }
        }

        if (!newAchievements.isEmpty()) {
            for (AchievementEntity achievement : achievementRepository.saveAll(newAchievements)) {
                achievements.put(achievement.getType(), achievement);
            }
        }
        return achievements;
    }

    private StreakResponse toResponse(
            StreakCalculation calculation,
            Map<String, AchievementEntity> achievements
    ) {
        return new StreakResponse(
                calculation.currentDays(),
                calculation.longestDays(),
                calculation.lastActiveDate(),
                MILESTONE_DAYS.stream()
                        .map(days -> toMilestoneResponse(days, achievements.get(milestoneType(days))))
                        .toList());
    }

    private StreakMilestoneResponse toMilestoneResponse(Integer days, AchievementEntity achievement) {
        return new StreakMilestoneResponse(
                days,
                achievement != null,
                achievement == null ? null : achievement.getAchievedAt());
    }

    private void ensureStreakNotice(UUID userId, Integer days, Instant triggeredAt) {
        retentionNoticeRepository.findByUserIdAndTypeAndMilestoneValue(userId, STREAK_NOTICE_TYPE, days)
                .orElseGet(() -> {
                    RetentionNoticeEntity notice = new RetentionNoticeEntity();
                    notice.setUserId(userId);
                    notice.setType(STREAK_NOTICE_TYPE);
                    notice.setMilestoneValue(days);
                    notice.setTitle("连续记录 " + days + " 天");
                    notice.setMessage("今天也完成记录，继续保持现在的节奏。");
                    notice.setStatus(RetentionNoticeStatus.PENDING.value());
                    notice.setTriggeredAt(triggeredAt);
                    return retentionNoticeRepository.save(notice);
                });
    }

    private RetentionNoticeResponse toNoticeResponse(RetentionNoticeEntity notice) {
        int currentValue = notice.getMilestoneValue();
        return new RetentionNoticeResponse(
                notice.getId(),
                notice.getType(),
                notice.getTitle(),
                notice.getMessage(),
                currentValue,
                previousMilestone(currentValue),
                nextMilestone(currentValue),
                notice.getTriggeredAt());
    }

    private Integer previousMilestone(int currentValue) {
        return MILESTONE_DAYS.stream()
                .filter(days -> days < currentValue)
                .reduce((left, right) -> right)
                .orElse(null);
    }

    private Integer nextMilestone(int currentValue) {
        return MILESTONE_DAYS.stream()
                .filter(days -> days > currentValue)
                .findFirst()
                .orElse(null);
    }

    private ZoneId zoneId(UUID userId) {
        return userProfileRepository.findByUserId(userId)
                .map(this::zoneId)
                .orElse(DEFAULT_ZONE_ID);
    }

    private ZoneId zoneId(UserProfileEntity profile) {
        try {
            return ZoneId.of(profile.getTimezone());
        } catch (DateTimeException exception) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "timezone 无效");
        }
    }

    private String milestoneType(Integer days) {
        return "streak_" + days;
    }

    private record StreakCalculation(
            int currentDays,
            int longestDays,
            LocalDate lastActiveDate
    ) {
    }
}
