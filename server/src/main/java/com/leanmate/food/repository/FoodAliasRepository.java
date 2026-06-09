package com.leanmate.food.repository;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FoodAliasRepository extends JpaRepository<FoodAliasEntity, UUID> {

    List<FoodAliasEntity> findByFoodIdOrderByAliasAsc(UUID foodId);

    @Modifying
    @Query("delete from FoodAliasEntity alias where alias.foodId = :foodId")
    int deleteByFoodId(@Param("foodId") UUID foodId);
}
