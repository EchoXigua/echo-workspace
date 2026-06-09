package com.leanmate.food.repository;

import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FoodCatalogRepository extends JpaRepository<FoodCatalogEntity, UUID> {

    @Query(
            value = """
                    select distinct food.*
                    from food_catalog food
                    left join food_aliases alias on alias.food_id = food.id
                    where food.verified = true
                      and (
                        food.normalized_name like concat('%', :term, '%')
                        or alias.normalized_alias like concat('%', :term, '%')
                      )
                    order by food.name asc
                    """,
            nativeQuery = true)
    List<FoodCatalogEntity> searchVerified(@Param("term") String term, Pageable pageable);
}
