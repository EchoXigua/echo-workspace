package com.leanmate.diet.repository;

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
@Table(name = "food_entries")
public class FoodEntryEntity {

    @Id
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "recognition_task_id")
    private UUID recognitionTaskId;

    @Column(name = "meal_date", nullable = false)
    private LocalDate mealDate;

    @Column(name = "meal_type", nullable = false, length = 16)
    private String mealType;

    @Column(name = "source_type", nullable = false, length = 16)
    private String sourceType;

    @Column(name = "raw_text")
    private String rawText;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "image_object_key")
    private String imageObjectKey;

    @Column(name = "status", nullable = false, length = 32)
    private String status;

    @Column(name = "total_calories_kcal", nullable = false)
    private Integer totalCaloriesKcal;

    @Column(name = "total_protein_g", nullable = false, precision = 8, scale = 2)
    private BigDecimal totalProteinG;

    @Column(name = "total_fat_g", nullable = false, precision = 8, scale = 2)
    private BigDecimal totalFatG;

    @Column(name = "total_carbs_g", nullable = false, precision = 8, scale = 2)
    private BigDecimal totalCarbsG;

    @Column(name = "confirmed_at")
    private Instant confirmedAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;

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

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public UUID getRecognitionTaskId() {
        return recognitionTaskId;
    }

    public void setRecognitionTaskId(UUID recognitionTaskId) {
        this.recognitionTaskId = recognitionTaskId;
    }

    public LocalDate getMealDate() {
        return mealDate;
    }

    public void setMealDate(LocalDate mealDate) {
        this.mealDate = mealDate;
    }

    public String getMealType() {
        return mealType;
    }

    public void setMealType(String mealType) {
        this.mealType = mealType;
    }

    public String getSourceType() {
        return sourceType;
    }

    public void setSourceType(String sourceType) {
        this.sourceType = sourceType;
    }

    public String getRawText() {
        return rawText;
    }

    public void setRawText(String rawText) {
        this.rawText = rawText;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Integer getTotalCaloriesKcal() {
        return totalCaloriesKcal;
    }

    public void setTotalCaloriesKcal(Integer totalCaloriesKcal) {
        this.totalCaloriesKcal = totalCaloriesKcal;
    }

    public BigDecimal getTotalProteinG() {
        return totalProteinG;
    }

    public void setTotalProteinG(BigDecimal totalProteinG) {
        this.totalProteinG = totalProteinG;
    }

    public BigDecimal getTotalFatG() {
        return totalFatG;
    }

    public void setTotalFatG(BigDecimal totalFatG) {
        this.totalFatG = totalFatG;
    }

    public BigDecimal getTotalCarbsG() {
        return totalCarbsG;
    }

    public void setTotalCarbsG(BigDecimal totalCarbsG) {
        this.totalCarbsG = totalCarbsG;
    }

    public Instant getConfirmedAt() {
        return confirmedAt;
    }

    public void setConfirmedAt(Instant confirmedAt) {
        this.confirmedAt = confirmedAt;
    }

    public Instant getDeletedAt() {
        return deletedAt;
    }

    public void setDeletedAt(Instant deletedAt) {
        this.deletedAt = deletedAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
