package com.leanmate.ai.repository;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ai_model_call_logs")
public class AiModelCallLogEntity {

    @Id
    private UUID id;

    @Column(name = "request_id", length = 64)
    private String requestId;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "business_type", nullable = false, length = 64)
    private String businessType;

    @Column(name = "business_id")
    private UUID businessId;

    @Column(name = "provider", nullable = false, length = 64)
    private String provider;

    @Column(name = "requested_model", length = 128)
    private String requestedModel;

    @Column(name = "response_model", length = 128)
    private String responseModel;

    @Column(name = "prompt_version", length = 64)
    private String promptVersion;

    @Column(name = "status", nullable = false, length = 32)
    private String status;

    @Column(name = "http_status")
    private Integer httpStatus;

    @Column(name = "provider_error_code", length = 128)
    private String providerErrorCode;

    @Column(name = "error_message")
    private String errorMessage;

    @Column(name = "prompt_tokens")
    private Integer promptTokens;

    @Column(name = "completion_tokens")
    private Integer completionTokens;

    @Column(name = "total_tokens")
    private Integer totalTokens;

    @Column(name = "estimated_cost_minor")
    private Integer estimatedCostMinor;

    @Column(name = "duration_ms")
    private Long durationMs;

    @Column(name = "attempt", nullable = false)
    private Integer attempt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (id == null) {
            id = UUID.randomUUID();
        }
        if (attempt == null || attempt <= 0) {
            attempt = 1;
        }
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getRequestId() {
        return requestId;
    }

    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getBusinessType() {
        return businessType;
    }

    public void setBusinessType(String businessType) {
        this.businessType = businessType;
    }

    public UUID getBusinessId() {
        return businessId;
    }

    public void setBusinessId(UUID businessId) {
        this.businessId = businessId;
    }

    public String getProvider() {
        return provider;
    }

    public void setProvider(String provider) {
        this.provider = provider;
    }

    public String getRequestedModel() {
        return requestedModel;
    }

    public void setRequestedModel(String requestedModel) {
        this.requestedModel = requestedModel;
    }

    public String getResponseModel() {
        return responseModel;
    }

    public void setResponseModel(String responseModel) {
        this.responseModel = responseModel;
    }

    public String getPromptVersion() {
        return promptVersion;
    }

    public void setPromptVersion(String promptVersion) {
        this.promptVersion = promptVersion;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Integer getHttpStatus() {
        return httpStatus;
    }

    public void setHttpStatus(Integer httpStatus) {
        this.httpStatus = httpStatus;
    }

    public String getProviderErrorCode() {
        return providerErrorCode;
    }

    public void setProviderErrorCode(String providerErrorCode) {
        this.providerErrorCode = providerErrorCode;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public Integer getPromptTokens() {
        return promptTokens;
    }

    public void setPromptTokens(Integer promptTokens) {
        this.promptTokens = promptTokens;
    }

    public Integer getCompletionTokens() {
        return completionTokens;
    }

    public void setCompletionTokens(Integer completionTokens) {
        this.completionTokens = completionTokens;
    }

    public Integer getTotalTokens() {
        return totalTokens;
    }

    public void setTotalTokens(Integer totalTokens) {
        this.totalTokens = totalTokens;
    }

    public Integer getEstimatedCostMinor() {
        return estimatedCostMinor;
    }

    public void setEstimatedCostMinor(Integer estimatedCostMinor) {
        this.estimatedCostMinor = estimatedCostMinor;
    }

    public Long getDurationMs() {
        return durationMs;
    }

    public void setDurationMs(Long durationMs) {
        this.durationMs = durationMs;
    }

    public Integer getAttempt() {
        return attempt;
    }

    public void setAttempt(Integer attempt) {
        this.attempt = attempt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}
