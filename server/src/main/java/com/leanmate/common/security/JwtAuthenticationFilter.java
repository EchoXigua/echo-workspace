package com.leanmate.common.security;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.common.web.RequestContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.UUID;
import org.slf4j.MDC;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtTokenService jwtTokenService;
    private final AuthenticationEntryPoint authenticationEntryPoint;

    public JwtAuthenticationFilter(
            JwtTokenService jwtTokenService,
            JsonAuthenticationEntryPoint authenticationEntryPoint
    ) {
        this.jwtTokenService = jwtTokenService;
        this.authenticationEntryPoint = authenticationEntryPoint;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        try {
            authenticateRequest(request);
        } catch (BusinessException exception) {
            SecurityContextHolder.clearContext();
            request.setAttribute(JsonAuthenticationEntryPoint.ERROR_CODE_ATTRIBUTE, exception.getErrorCode());
            authenticationEntryPoint.commence(
                    request,
                    response,
                    new BadCredentialsException(exception.getMessage(), exception));
            return;
        }

        try {
            filterChain.doFilter(request, response);
        } finally {
            CurrentUserContext.clear();
        }
    }

    private void authenticateRequest(HttpServletRequest request) {
        String token = resolveToken(request);
        if (token == null) {
            return;
        }

        UUID userId = jwtTokenService.parseUserId(token);
        CurrentUser currentUser = new CurrentUser(userId);
        CurrentUserContext.set(currentUser);
        request.setAttribute(RequestContext.USER_ID_ATTRIBUTE, userId.toString());
        MDC.put("userId", userId.toString());
        UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken(currentUser, token, List.of());
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    private String resolveToken(HttpServletRequest request) {
        String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (!StringUtils.hasText(authorization)) {
            return null;
        }
        if (!authorization.startsWith(BEARER_PREFIX)) {
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
        }

        String token = authorization.substring(BEARER_PREFIX.length()).trim();
        if (!StringUtils.hasText(token)) {
            throw new BusinessException(ErrorCode.INVALID_TOKEN);
        }
        return token;
    }
}
