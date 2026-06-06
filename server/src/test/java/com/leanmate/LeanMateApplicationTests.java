package com.leanmate;

import com.leanmate.user.repository.RefreshTokenRepository;
import com.leanmate.user.repository.UserAuthIdentityRepository;
import com.leanmate.user.repository.UserProfileRepository;
import com.leanmate.user.repository.UserRepository;
import com.leanmate.user.repository.WeightGoalRepository;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

@SpringBootTest(properties = {
        "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,"
                + "org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration,"
                + "org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration,"
                + "org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration"
})
class LeanMateApplicationTests {

    @MockitoBean
    UserRepository userRepository;

    @MockitoBean
    UserAuthIdentityRepository userAuthIdentityRepository;

    @MockitoBean
    RefreshTokenRepository refreshTokenRepository;

    @MockitoBean
    UserProfileRepository userProfileRepository;

    @MockitoBean
    WeightGoalRepository weightGoalRepository;

    @Test
    void contextLoads() {
    }
}
