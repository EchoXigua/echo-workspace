package com.leanmate.ai.client;

public class AiProviderException extends RuntimeException {

    private final String providerErrorCode;

    public AiProviderException(String providerErrorCode, String message) {
        super(message);
        this.providerErrorCode = providerErrorCode;
    }

    public String providerErrorCode() {
        return providerErrorCode;
    }
}
