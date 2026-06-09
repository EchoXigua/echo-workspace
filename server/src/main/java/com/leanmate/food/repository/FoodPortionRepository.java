package com.leanmate.food.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FoodPortionRepository extends JpaRepository<FoodPortionEntity, UUID> {

    Optional<FoodPortionEntity> findByFoodIdAndDefaultPortionTrue(UUID foodId);

    Optional<FoodPortionEntity> findByIdAndFoodId(UUID id, UUID foodId);

    List<FoodPortionEntity> findByFoodIdOrderBySortOrderAsc(UUID foodId);
}
