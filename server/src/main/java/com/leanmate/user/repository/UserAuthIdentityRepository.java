package com.leanmate.user.repository;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserAuthIdentityRepository extends JpaRepository<UserAuthIdentityEntity, UUID> {

    Optional<UserAuthIdentityEntity> findByProviderAndProviderUserId(String provider, String providerUserId);
}
