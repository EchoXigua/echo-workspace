package com.leanmate.food.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FoodPortionRepository extends JpaRepository<FoodPortionEntity, UUID> {

    Optional<FoodPortionEntity> findByFoodIdAndDefaultPortionTrue(UUID foodId);

    Optional<FoodPortionEntity> findByIdAndFoodId(UUID id, UUID foodId);

    List<FoodPortionEntity> findByFoodIdOrderBySortOrderAsc(UUID foodId);

    @Modifying
    @Query("delete from FoodPortionEntity portion where portion.foodId = :foodId")
    int deleteByFoodId(@Param("foodId") UUID foodId);
}
