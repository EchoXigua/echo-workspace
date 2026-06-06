package com.leanmate.diet.repository;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FoodItemRepository extends JpaRepository<FoodItemEntity, UUID> {

    List<FoodItemEntity> findByFoodEntryIdOrderBySortOrderAsc(UUID foodEntryId);

    void deleteByFoodEntryId(UUID foodEntryId);
}
