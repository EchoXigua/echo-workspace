package com.leanmate.ai.application;

import com.leanmate.ai.repository.AiModelCallLogEntity;
import com.leanmate.ai.repository.AiModelCallLogRepository;
import com.leanmate.common.web.ObservabilityProperties;
import com.leanmate.common.web.RequestContext;
import java.time.Instant;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.util.StringUtils;

@Service
public class AiModelCallLogService {

    private static final Logger log = LoggerFactory.getLogger(AiModelCallLogService.class);

    private final AiModelCallLogRepository aiModelCallLogRepository;
    private final ObservabilityProperties observabilityProperties;
    private final TransactionTemplate transactionTemplate;

    public AiModelCallLogService(
            AiModelCallLogRepository aiModelCallLogRepository,
            ObservabilityProperties observabilityProperties,
            PlatformTransactionManager transactionManager
    ) {
        this.aiModelCallLogRepository = aiModelCallLogRepository;
        this.observabilityProperties = observabilityProperties;
        this.transactionTemplate = new TransactionTemplate(transactionManager);
        this.transactionTemplate.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }

    public void record(AiModelCallLogCommand command) {
        if (!observabilityProperties.aiCallLogEnabled() || command == null) {
            return;
        }
        try {
            transactionTemplate.executeWithoutResult(status -> aiModelCallLogRepository.save(toEntity(command)));
        } catch (RuntimeException exception) {
            log.warn("AI 调用审计写入失败 businessType={}, businessId={}, error={}",
                    command.businessType(),
                    command.businessId(),
                    exception.getClass().getName());
        }
    }

    private AiModelCallLogEntity toEntity(AiModelCallLogCommand command) {
        AiModelCallLogEntity entity = new AiModelCallLogEntity();
        entity.setId(UUID.randomUUID());
        entity.setRequestId(defaultIfBlank(command.requestId(), RequestContext.getOrCreateRequestId()));
        entity.setUserId(command.userId());
        entity.setBusinessType(command.businessType());
        entity.setBusinessId(command.businessId());
        entity.setProvider(command.provider());
        entity.setRequestedModel(command.requestedModel());
        entity.setResponseModel(command.responseModel());
        entity.setPromptVersion(command.promptVersion());
        entity.setStatus(command.status());
        entity.setHttpStatus(command.httpStatus());
        entity.setProviderErrorCode(command.providerErrorCode());
        entity.setErrorMessage(command.errorMessage());
        entity.setPromptTokens(command.promptTokens());
        entity.setCompletionTokens(command.completionTokens());
        entity.setTotalTokens(command.totalTokens());
        entity.setEstimatedCostMinor(command.estimatedCostMinor());
        entity.setDurationMs(command.durationMs());
        entity.setAttempt(command.attempt() <= 0 ? 1 : command.attempt());
        entity.setCreatedAt(command.createdAt() == null ? Instant.now() : command.createdAt());
        return entity;
    }

    private String defaultIfBlank(String value, String fallback) {
        return StringUtils.hasText(value) ? value.trim() : fallback;
    }

    public record AiModelCallLogCommand(
            String requestId,
            UUID userId,
            String businessType,
            UUID businessId,
            String provider,
            String requestedModel,
            String responseModel,
            String promptVersion,
            String status,
            Integer httpStatus,
            String providerErrorCode,
            String errorMessage,
            Integer promptTokens,
            Integer completionTokens,
            Integer totalTokens,
            Integer estimatedCostMinor,
            Long durationMs,
            int attempt,
            Instant createdAt
    ) {
    }
}
