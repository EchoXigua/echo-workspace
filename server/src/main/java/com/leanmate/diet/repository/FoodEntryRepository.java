package com.leanmate.diet.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FoodEntryRepository extends JpaRepository<FoodEntryEntity, UUID> {

    List<FoodEntryEntity> findByUserIdAndMealDateAndStatusOrderByCreatedAtAsc(
            UUID userId,
            LocalDate mealDate,
            String status);
}
