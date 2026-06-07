package com.leanmate.diet.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FoodEntryRepository extends JpaRepository<FoodEntryEntity, UUID> {

    List<FoodEntryEntity> findByUserIdAndMealDateAndStatusOrderByCreatedAtAsc(
            UUID userId,
            LocalDate mealDate,
            String status);

    @Query("""
            select distinct entry.mealDate
            from FoodEntryEntity entry
            where entry.userId = :userId
              and entry.status = :status
              and entry.mealDate <= :endDate
            order by entry.mealDate asc
            """)
    List<LocalDate> findDistinctMealDatesOnOrBefore(
            @Param("userId") UUID userId,
            @Param("status") String status,
            @Param("endDate") LocalDate endDate);
}
