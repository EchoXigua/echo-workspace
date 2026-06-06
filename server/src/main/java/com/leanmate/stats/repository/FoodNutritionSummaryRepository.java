package com.leanmate.stats.repository;

import java.time.LocalDate;
import java.util.UUID;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

public interface FoodNutritionSummaryRepository extends Repository<DailyNutritionSnapshotEntity, UUID> {

    @Query(value = """
            select
                count(*) as foodEntryCount,
                cast(coalesce(sum(total_calories_kcal), 0) as integer) as caloriesKcal,
                coalesce(sum(total_protein_g), 0) as proteinG,
                coalesce(sum(total_fat_g), 0) as fatG,
                coalesce(sum(total_carbs_g), 0) as carbsG
            from food_entries
            where user_id = :userId
              and meal_date = :date
              and status = 'confirmed'
            """, nativeQuery = true)
    FoodNutritionSummaryRow summarizeConfirmedEntries(
            @Param("userId") UUID userId,
            @Param("date") LocalDate date);
}
