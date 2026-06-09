package com.leanmate.settings.application;

import com.leanmate.settings.dto.UserSettingsRequest;
import com.leanmate.settings.dto.UserSettingsResponse;
import com.leanmate.settings.repository.UserSettingsEntity;
import com.leanmate.settings.repository.UserSettingsRepository;
import com.leanmate.user.application.CurrentUserApplicationService;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserSettingsApplicationService {

    private final CurrentUserApplicationService currentUserApplicationService;
    private final UserSettingsRepository userSettingsRepository;

    public UserSettingsApplicationService(
            CurrentUserApplicationService currentUserApplicationService,
            UserSettingsRepository userSettingsRepository
    ) {
        this.currentUserApplicationService = currentUserApplicationService;
        this.userSettingsRepository = userSettingsRepository;
    }

    @Transactional(readOnly = true)
    public UserSettingsResponse getSettings(UUID userId) {
        currentUserApplicationService.requireActiveUser(userId);
        return userSettingsRepository.findByUserId(userId)
                .map(this::toResponse)
                .orElseGet(this::defaultSettings);
    }

    @Transactional
    public UserSettingsResponse saveSettings(UUID userId, UserSettingsRequest request) {
        currentUserApplicationService.requireActiveUser(userId);
        UserSettingsEntity settings = userSettingsRepository.findByUserId(userId)
                .orElseGet(UserSettingsEntity::new);
        settings.setUserId(userId);
        if (request.mealReminderEnabled() != null) {
            settings.setMealReminderEnabled(request.mealReminderEnabled());
        }
        if (request.mealReminderTimes() != null) {
            settings.setMealReminderTimes(new ArrayList<>(request.mealReminderTimes()));
        }
        if (request.milestoneNoticeEnabled() != null) {
            settings.setMilestoneNoticeEnabled(request.milestoneNoticeEnabled());
        }
        if (request.autoSyncEnabled() != null) {
            settings.setAutoSyncEnabled(request.autoSyncEnabled());
        }
        return toResponse(userSettingsRepository.save(settings));
    }

    private UserSettingsResponse defaultSettings() {
        return new UserSettingsResponse(false, List.of(), true, true);
    }

    private UserSettingsResponse toResponse(UserSettingsEntity settings) {
        return new UserSettingsResponse(
                Boolean.TRUE.equals(settings.getMealReminderEnabled()),
                settings.getMealReminderTimes() == null ? List.of() : settings.getMealReminderTimes(),
                Boolean.TRUE.equals(settings.getMilestoneNoticeEnabled()),
                Boolean.TRUE.equals(settings.getAutoSyncEnabled()));
    }
}
