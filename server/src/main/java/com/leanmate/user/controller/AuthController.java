package com.leanmate.user.controller;

import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.user.application.AuthApplicationService;
import com.leanmate.user.dto.AuthTokenResponse;
import com.leanmate.user.dto.LogoutRequest;
import com.leanmate.user.dto.OAuthLoginRequest;
import com.leanmate.user.dto.RefreshTokenRequest;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/auth")
public class AuthController {

    private final AuthApplicationService authApplicationService;

    public AuthController(AuthApplicationService authApplicationService) {
        this.authApplicationService = authApplicationService;
    }

    @PostMapping("/oauth-login")
    public ApiResponse<AuthTokenResponse> oauthLogin(@Valid @RequestBody OAuthLoginRequest request) {
        return ApiResponse.success(authApplicationService.oauthLogin(request));
    }

    @PostMapping("/refresh")
    public ApiResponse<AuthTokenResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        return ApiResponse.success(authApplicationService.refresh(request));
    }

    @PostMapping("/logout")
    public ApiResponse<Void> logout(@RequestBody(required = false) LogoutRequest request) {
        authApplicationService.logout(CurrentUserContext.getRequired().userId(), request);
        return ApiResponse.success();
    }
}
