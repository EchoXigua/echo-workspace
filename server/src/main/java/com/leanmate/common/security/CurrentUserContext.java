package com.leanmate.common.security;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import java.util.Optional;

public final class CurrentUserContext {

    private static final ThreadLocal<CurrentUser> HOLDER = new ThreadLocal<>();

    private CurrentUserContext() {
    }

    public static void set(CurrentUser currentUser) {
        HOLDER.set(currentUser);
    }

    public static Optional<CurrentUser> get() {
        return Optional.ofNullable(HOLDER.get());
    }

    public static CurrentUser getRequired() {
        return get().orElseThrow(() -> new BusinessException(ErrorCode.UNAUTHORIZED));
    }

    public static void clear() {
        HOLDER.remove();
    }
}
