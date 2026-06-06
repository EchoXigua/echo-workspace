package com.leanmate.diet.repository;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "ai_recognition_tasks")
public class AiRecognitionTaskEntity {

    @Id
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "source_type", nullable = false, length = 16)
    private String sourceType;

    @Column(name = "meal_date")
    private LocalDate mealDate;

    @Column(name = "meal_type", length = 16)
    private String mealType;

    @Column(name = "input_text")
    private String inputText;

    @Column(name = "input_image_url")
    private String inputImageUrl;

    @Column(name = "input_object_key")
    private String inputObjectKey;

    @Column(name = "status", nullable = false, length = 32)
    private String status;

    @Column(name = "model_name", length = 128)
    private String modelName;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "raw_output", columnDefinition = "jsonb")
    private Map<String, Object> rawOutput;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "structured_result", columnDefinition = "jsonb")
    private Map<String, Object> structuredResult;

    @Column(name = "error_code", length = 64)
    private String errorCode;

    @Column(name = "error_message")
    private String errorMessage;

    @Column(name = "started_at")
    private Instant startedAt;

    @Column(name = "finished_at")
    private Instant finishedAt;

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
        if (createdAt == null) {
            createdAt = now;
        }
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

    public String getSourceType() {
        return sourceType;
    }

    public void setSourceType(String sourceType) {
        this.sourceType = sourceType;
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

    public String getInputText() {
        return inputText;
    }

    public void setInputText(String inputText) {
        this.inputText = inputText;
    }

    public String getInputImageUrl() {
        return inputImageUrl;
    }

    public void setInputImageUrl(String inputImageUrl) {
        this.inputImageUrl = inputImageUrl;
    }

    public String getInputObjectKey() {
        return inputObjectKey;
    }

    public void setInputObjectKey(String inputObjectKey) {
        this.inputObjectKey = inputObjectKey;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getModelName() {
        return modelName;
    }

    public void setModelName(String modelName) {
        this.modelName = modelName;
    }

    public Map<String, Object> getRawOutput() {
        return rawOutput;
    }

    public void setRawOutput(Map<String, Object> rawOutput) {
        this.rawOutput = rawOutput;
    }

    public Map<String, Object> getStructuredResult() {
        return structuredResult;
    }

    public void setStructuredResult(Map<String, Object> structuredResult) {
        this.structuredResult = structuredResult;
    }

    public String getErrorCode() {
        return errorCode;
    }

    public void setErrorCode(String errorCode) {
        this.errorCode = errorCode;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public Instant getStartedAt() {
        return startedAt;
    }

    public void setStartedAt(Instant startedAt) {
        this.startedAt = startedAt;
    }

    public Instant getFinishedAt() {
        return finishedAt;
    }

    public void setFinishedAt(Instant finishedAt) {
        this.finishedAt = finishedAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}
