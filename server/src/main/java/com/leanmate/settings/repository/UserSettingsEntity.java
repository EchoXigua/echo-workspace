package com.leanmate.settings.repository;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "user_settings")
public class UserSettingsEntity {

    @Id
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "meal_reminder_enabled", nullable = false)
    private Boolean mealReminderEnabled;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "meal_reminder_times", nullable = false, columnDefinition = "jsonb")
    private List<String> mealReminderTimes;

    @Column(name = "milestone_notice_enabled", nullable = false)
    private Boolean milestoneNoticeEnabled;

    @Column(name = "auto_sync_enabled", nullable = false)
    private Boolean autoSyncEnabled;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (id == null) {
            id = UUID.randomUUID();
        }
        applyDefaults();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        applyDefaults();
        updatedAt = Instant.now();
    }

    private void applyDefaults() {
        if (mealReminderEnabled == null) {
            mealReminderEnabled = false;
        }
        if (mealReminderTimes == null) {
            mealReminderTimes = new ArrayList<>();
        }
        if (milestoneNoticeEnabled == null) {
            milestoneNoticeEnabled = true;
        }
        if (autoSyncEnabled == null) {
            autoSyncEnabled = true;
        }
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public Boolean getMealReminderEnabled() {
        return mealReminderEnabled;
    }

    public void setMealReminderEnabled(Boolean mealReminderEnabled) {
        this.mealReminderEnabled = mealReminderEnabled;
    }

    public List<String> getMealReminderTimes() {
        return mealReminderTimes;
    }

    public void setMealReminderTimes(List<String> mealReminderTimes) {
        this.mealReminderTimes = mealReminderTimes;
    }

    public Boolean getMilestoneNoticeEnabled() {
        return milestoneNoticeEnabled;
    }

    public void setMilestoneNoticeEnabled(Boolean milestoneNoticeEnabled) {
        this.milestoneNoticeEnabled = milestoneNoticeEnabled;
    }

    public Boolean getAutoSyncEnabled() {
        return autoSyncEnabled;
    }

    public void setAutoSyncEnabled(Boolean autoSyncEnabled) {
        this.autoSyncEnabled = autoSyncEnabled;
    }
}
