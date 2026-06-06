package com.leanmate.user.repository;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "user_profiles")
public class UserProfileEntity {

    @Id
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "gender", nullable = false, length = 16)
    private String gender;

    @Column(name = "age", nullable = false)
    private Integer age;

    @Column(name = "height_cm", nullable = false, precision = 5, scale = 2)
    private BigDecimal heightCm;

    @Column(name = "current_weight_kg", nullable = false, precision = 5, scale = 2)
    private BigDecimal currentWeightKg;

    @Column(name = "target_weight_kg", nullable = false, precision = 5, scale = 2)
    private BigDecimal targetWeightKg;

    @Column(name = "activity_level", nullable = false, length = 32)
    private String activityLevel;

    @Column(name = "timezone", nullable = false, length = 64)
    private String timezone;

    @Column(name = "bmi", nullable = false, precision = 5, scale = 2)
    private BigDecimal bmi;

    @Column(name = "bmr_kcal", nullable = false)
    private Integer bmrKcal;

    @Column(name = "daily_calorie_target_kcal", nullable = false)
    private Integer dailyCalorieTargetKcal;

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
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }

    public Integer getAge() {
        return age;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    public BigDecimal getHeightCm() {
        return heightCm;
    }

    public void setHeightCm(BigDecimal heightCm) {
        this.heightCm = heightCm;
    }

    public BigDecimal getCurrentWeightKg() {
        return currentWeightKg;
    }

    public void setCurrentWeightKg(BigDecimal currentWeightKg) {
        this.currentWeightKg = currentWeightKg;
    }

    public BigDecimal getTargetWeightKg() {
        return targetWeightKg;
    }

    public void setTargetWeightKg(BigDecimal targetWeightKg) {
        this.targetWeightKg = targetWeightKg;
    }

    public String getActivityLevel() {
        return activityLevel;
    }

    public void setActivityLevel(String activityLevel) {
        this.activityLevel = activityLevel;
    }

    public String getTimezone() {
        return timezone;
    }

    public void setTimezone(String timezone) {
        this.timezone = timezone;
    }

    public BigDecimal getBmi() {
        return bmi;
    }

    public void setBmi(BigDecimal bmi) {
        this.bmi = bmi;
    }

    public Integer getBmrKcal() {
        return bmrKcal;
    }

    public void setBmrKcal(Integer bmrKcal) {
        this.bmrKcal = bmrKcal;
    }

    public Integer getDailyCalorieTargetKcal() {
        return dailyCalorieTargetKcal;
    }

    public void setDailyCalorieTargetKcal(Integer dailyCalorieTargetKcal) {
        this.dailyCalorieTargetKcal = dailyCalorieTargetKcal;
    }
}
