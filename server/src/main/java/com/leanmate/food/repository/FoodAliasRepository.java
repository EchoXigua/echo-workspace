package com.leanmate.food.repository;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FoodAliasRepository extends JpaRepository<FoodAliasEntity, UUID> {

    List<FoodAliasEntity> findByFoodIdOrderByAliasAsc(UUID foodId);
}
