package com.leanmate.ai.client;

public class AiProviderException extends RuntimeException {

    private final String providerErrorCode;
    private final Integer providerHttpStatus;

    public AiProviderException(String providerErrorCode, String message) {
        this(providerErrorCode, message, null);
    }

    public AiProviderException(String providerErrorCode, String message, Integer providerHttpStatus) {
        super(message);
        this.providerErrorCode = providerErrorCode;
        this.providerHttpStatus = providerHttpStatus;
    }

    public String providerErrorCode() {
        return providerErrorCode;
    }

    public Integer providerHttpStatus() {
        return providerHttpStatus;
    }
}
