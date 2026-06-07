package com.leanmate.weight.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface WeightEntryRepository extends JpaRepository<WeightEntryEntity, UUID> {

    Optional<WeightEntryEntity> findByUserIdAndRecordDate(UUID userId, LocalDate recordDate);

    List<WeightEntryEntity> findByUserIdAndRecordDateBetweenOrderByRecordDateAsc(
            UUID userId,
            LocalDate startDate,
            LocalDate endDate);

    Optional<WeightEntryEntity> findFirstByUserIdAndRecordDateLessThanEqualOrderByRecordDateDesc(
            UUID userId,
            LocalDate recordDate);

    @Query("""
            select distinct entry.recordDate
            from WeightEntryEntity entry
            where entry.userId = :userId
              and entry.recordDate <= :endDate
            order by entry.recordDate asc
            """)
    List<LocalDate> findDistinctRecordDatesOnOrBefore(
            @Param("userId") UUID userId,
            @Param("endDate") LocalDate endDate);
}
