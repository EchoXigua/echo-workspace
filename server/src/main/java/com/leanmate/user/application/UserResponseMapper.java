package com.leanmate.user.application;

import com.leanmate.user.domain.UserStatus;
import com.leanmate.user.dto.CurrentUserResponse;
import com.leanmate.user.repository.UserEntity;
import org.springframework.stereotype.Component;

@Component
public class UserResponseMapper {

    public CurrentUserResponse toCurrentUserResponse(UserEntity user, boolean profileCompleted) {
        return new CurrentUserResponse(
                user.getId(),
                user.getNickname(),
                user.getAvatarUrl(),
                UserStatus.fromValue(user.getStatus()),
                profileCompleted,
                user.getCreatedAt());
    }
}
