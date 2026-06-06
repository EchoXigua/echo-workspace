package com.leanmate.user.application;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.user.domain.UserStatus;
import com.leanmate.user.dto.CurrentUserResponse;
import com.leanmate.user.repository.UserEntity;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.user.repository.UserRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CurrentUserApplicationService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final UserResponseMapper userResponseMapper;

    public CurrentUserApplicationService(
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            UserResponseMapper userResponseMapper
    ) {
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.userResponseMapper = userResponseMapper;
    }

    @Transactional(readOnly = true)
    public CurrentUserResponse getCurrentUser(UUID userId) {
        UserEntity user = requireActiveUser(userId);
        boolean profileCompleted = userProfileRepository.existsByUserId(userId);
        return userResponseMapper.toCurrentUserResponse(user, profileCompleted);
    }

    UserEntity requireActiveUser(UUID userId) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_TOKEN));
        if (!UserStatus.ACTIVE.value().equals(user.getStatus())) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "账号不可用");
        }
        return user;
    }
}
