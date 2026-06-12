package com.leanmate.common.web;

import java.util.UUID;
import java.util.regex.Pattern;
import org.springframework.util.StringUtils;

public final class RequestContext {

    public static final String REQUEST_ID_HEADER = "X-Request-Id";
    public static final String USER_ID_ATTRIBUTE = "leanmate.userId";

    private static final Pattern SAFE_REQUEST_ID = Pattern.compile("[A-Za-z0-9._-]{8,64}");
    private static final ThreadLocal<String> REQUEST_ID_HOLDER = new ThreadLocal<>();

    private RequestContext() {
    }

    public static String resolveRequestId(String candidate) {
        if (StringUtils.hasText(candidate)) {
            String trimmed = candidate.trim();
            if (SAFE_REQUEST_ID.matcher(trimmed).matches()) {
                return trimmed;
            }
        }
        return UUID.randomUUID().toString();
    }

    public static void setRequestId(String requestId) {
        REQUEST_ID_HOLDER.set(requestId);
    }

    public static String getRequestId() {
        return REQUEST_ID_HOLDER.get();
    }

    public static String getOrCreateRequestId() {
        String requestId = getRequestId();
        if (requestId != null) {
            return requestId;
        }
        requestId = UUID.randomUUID().toString();
        setRequestId(requestId);
        return requestId;
    }

    public static void clear() {
        REQUEST_ID_HOLDER.remove();
    }
}
