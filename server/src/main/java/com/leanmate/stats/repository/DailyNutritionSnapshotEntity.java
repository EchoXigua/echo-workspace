package com.leanmate.stats.repository;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "daily_nutrition_snapshots")
public class DailyNutritionSnapshotEntity {

    @Id
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "date", nullable = false)
    private LocalDate date;

    @Column(name = "calorie_target_kcal", nullable = false)
    private Integer calorieTargetKcal;

    @Column(name = "calories_kcal", nullable = false)
    private Integer caloriesKcal;

    @Column(name = "protein_g", nullable = false, precision = 8, scale = 2)
    private BigDecimal proteinG;

    @Column(name = "fat_g", nullable = false, precision = 8, scale = 2)
    private BigDecimal fatG;

    @Column(name = "carbs_g", nullable = false, precision = 8, scale = 2)
    private BigDecimal carbsG;

    @Column(name = "remaining_calories_kcal", nullable = false)
    private Integer remainingCaloriesKcal;

    @Column(name = "food_entry_count", nullable = false)
    private Integer foodEntryCount;

    @Column(name = "weight_kg", precision = 5, scale = 2)
    private BigDecimal weightKg;

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

    public LocalDate getDate() {
        return date;
    }

    public void setDate(LocalDate date) {
        this.date = date;
    }

    public Integer getCalorieTargetKcal() {
        return calorieTargetKcal;
    }

    public void setCalorieTargetKcal(Integer calorieTargetKcal) {
        this.calorieTargetKcal = calorieTargetKcal;
    }

    public Integer getCaloriesKcal() {
        return caloriesKcal;
    }

    public void setCaloriesKcal(Integer caloriesKcal) {
        this.caloriesKcal = caloriesKcal;
    }

    public BigDecimal getProteinG() {
        return proteinG;
    }

    public void setProteinG(BigDecimal proteinG) {
        this.proteinG = proteinG;
    }

    public BigDecimal getFatG() {
        return fatG;
    }

    public void setFatG(BigDecimal fatG) {
        this.fatG = fatG;
    }

    public BigDecimal getCarbsG() {
        return carbsG;
    }

    public void setCarbsG(BigDecimal carbsG) {
        this.carbsG = carbsG;
    }

    public Integer getRemainingCaloriesKcal() {
        return remainingCaloriesKcal;
    }

    public void setRemainingCaloriesKcal(Integer remainingCaloriesKcal) {
        this.remainingCaloriesKcal = remainingCaloriesKcal;
    }

    public Integer getFoodEntryCount() {
        return foodEntryCount;
    }

    public void setFoodEntryCount(Integer foodEntryCount) {
        this.foodEntryCount = foodEntryCount;
    }

    public BigDecimal getWeightKg() {
        return weightKg;
    }

    public void setWeightKg(BigDecimal weightKg) {
        this.weightKg = weightKg;
    }
}
