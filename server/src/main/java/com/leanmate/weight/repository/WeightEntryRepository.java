package com.leanmate.weight.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WeightEntryRepository extends JpaRepository<WeightEntryEntity, UUID> {

    Optional<WeightEntryEntity> findByUserIdAndRecordDate(UUID userId, LocalDate recordDate);

    List<WeightEntryEntity> findByUserIdAndRecordDateBetweenOrderByRecordDateAsc(
            UUID userId,
            LocalDate startDate,
            LocalDate endDate);

    Optional<WeightEntryEntity> findFirstByUserIdAndRecordDateLessThanEqualOrderByRecordDateDesc(
            UUID userId,
            LocalDate recordDate);
}
