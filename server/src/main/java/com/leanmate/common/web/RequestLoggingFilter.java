package com.leanmate.common.web;

import com.leanmate.common.security.CurrentUser;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RequestLoggingFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(RequestLoggingFilter.class);
    private static final String CLIENT_PLATFORM_HEADER = "X-Client-Platform";
    private static final String APP_VERSION_HEADER = "X-App-Version";

    private final ObservabilityProperties observabilityProperties;

    public RequestLoggingFilter(ObservabilityProperties observabilityProperties) {
        this.observabilityProperties = observabilityProperties;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        long startedAt = System.nanoTime();
        String requestId = RequestContext.resolveRequestId(request.getHeader(RequestContext.REQUEST_ID_HEADER));
        String path = request.getRequestURI();
        String method = request.getMethod();
        String platform = normalizeHeader(request.getHeader(CLIENT_PLATFORM_HEADER));
        String appVersion = normalizeHeader(request.getHeader(APP_VERSION_HEADER));

        RequestContext.setRequestId(requestId);
        response.setHeader(RequestContext.REQUEST_ID_HEADER, requestId);
        MDC.put("requestId", requestId);
        MDC.put("method", method);
        MDC.put("path", path);
        putIfPresent("clientPlatform", platform);
        putIfPresent("appVersion", appVersion);

        try {
            filterChain.doFilter(request, response);
        } finally {
            long durationMs = (System.nanoTime() - startedAt) / 1_000_000L;
            if (observabilityProperties.accessLogEnabled()) {
                logAccess(request, response, requestId, method, path, platform, appVersion, durationMs);
            }
            MDC.clear();
            RequestContext.clear();
        }
    }

    private void logAccess(
            HttpServletRequest request,
            HttpServletResponse response,
            String requestId,
            String method,
            String path,
            String platform,
            String appVersion,
            long durationMs
    ) {
        int status = response.getStatus();
        String userId = resolveUserId(request);
        putIfPresent("userId", userId);

        String message = "event=api_access"
                + " requestId=" + value(requestId)
                + " userId=" + value(userId)
                + " method=" + value(method)
                + " path=" + value(path)
                + " queryKeys=" + value(queryKeys(request))
                + " status=" + status
                + " durationMs=" + durationMs
                + " slow=" + (durationMs >= observabilityProperties.accessLogSlowThresholdMs())
                + " requestSizeBytes=" + request.getContentLengthLong()
                + " clientIpHash=" + value(hash(remoteAddress(request)))
                + " userAgentHash=" + value(hash(request.getHeader(HttpHeaders.USER_AGENT)))
                + " platform=" + value(platform)
                + " appVersion=" + value(appVersion);

        if (status >= 500) {
            log.error(message);
        } else if (status >= 400) {
            log.warn(message);
        } else {
            log.info(message);
        }
    }

    private String resolveUserId(HttpServletRequest request) {
        Object userIdAttribute = request.getAttribute(RequestContext.USER_ID_ATTRIBUTE);
        if (userIdAttribute != null) {
            return userIdAttribute.toString();
        }
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof CurrentUser currentUser) {
            UUID userId = currentUser.userId();
            return userId == null ? null : userId.toString();
        }
        return null;
    }

    private String queryKeys(HttpServletRequest request) {
        if (!observabilityProperties.accessLogIncludeQueryKeys() || request.getParameterMap().isEmpty()) {
            return "[]";
        }
        List<String> keys = Arrays.stream(request.getParameterMap().keySet().toArray(String[]::new))
                .filter(StringUtils::hasText)
                .sorted(Comparator.naturalOrder())
                .toList();
        return "[" + String.join(",", keys) + "]";
    }

    private String remoteAddress(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (StringUtils.hasText(forwardedFor)) {
            return forwardedFor.split(",", 2)[0].trim();
        }
        return request.getRemoteAddr();
    }

    private String hash(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(value.trim().getBytes(StandardCharsets.UTF_8));
            return "sha256:" + HexFormat.of().formatHex(hashed, 0, 8);
        } catch (NoSuchAlgorithmException exception) {
            return "sha256:unavailable";
        }
    }

    private String normalizeHeader(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        String trimmed = value.trim();
        if (trimmed.length() > 64) {
            return trimmed.substring(0, 64);
        }
        return trimmed;
    }

    private void putIfPresent(String key, String value) {
        if (StringUtils.hasText(value)) {
            MDC.put(key, value);
        }
    }

    private String value(String value) {
        return StringUtils.hasText(value) ? value : "-";
    }
}
