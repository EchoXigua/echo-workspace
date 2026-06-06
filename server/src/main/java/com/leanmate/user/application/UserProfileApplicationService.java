package com.leanmate.user.application;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.user.domain.ActivityLevel;
import com.leanmate.user.domain.Gender;
import com.leanmate.user.domain.ProfileCalculationResult;
import com.leanmate.user.domain.ProfileCalculator;
import com.leanmate.user.domain.WeightGoalStatus;
import com.leanmate.user.dto.ProfilePayload;
import com.leanmate.user.dto.SaveUserProfileRequest;
import com.leanmate.user.dto.UserProfileResponse;
import com.leanmate.user.repository.UserProfileEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.user.repository.WeightGoalEntity;
import com.leanmate.user.repository.WeightGoalRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DateTimeException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserProfileApplicationService {

    private final CurrentUserApplicationService currentUserApplicationService;
    private final UserProfileRepository userProfileRepository;
    private final WeightGoalRepository weightGoalRepository;
    private final ProfileCalculator profileCalculator;

    public UserProfileApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserProfileRepository userProfileRepository,
            WeightGoalRepository weightGoalRepository,
            ProfileCalculator profileCalculator
    ) {
        this.currentUserApplicationService = currentUserApplicationService;
        this.userProfileRepository = userProfileRepository;
        this.weightGoalRepository = weightGoalRepository;
        this.profileCalculator = profileCalculator;
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

    private BigDecimal scaleWeightOrHeight(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }
}
