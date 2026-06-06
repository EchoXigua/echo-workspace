package com.leanmate.stats.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

public interface FoodEntrySummaryRepository extends Repository<DailyNutritionSnapshotEntity, UUID> {

    @Query(value = """
            select
                fe.id as id,
                fe.meal_type as mealType,
                fe.total_calories_kcal as totalCaloriesKcal,
                coalesce(string_agg(fi.name, chr(31) order by fi.sort_order), '') as itemNamesText
            from food_entries fe
            left join food_items fi on fi.food_entry_id = fe.id
            where fe.user_id = :userId
              and fe.meal_date = :date
              and fe.status = 'confirmed'
            group by fe.id, fe.meal_type, fe.total_calories_kcal, fe.created_at
            order by fe.created_at asc
            """, nativeQuery = true)
    List<FoodEntrySummaryRow> findConfirmedSummaries(
            @Param("userId") UUID userId,
            @Param("date") LocalDate date);
}
