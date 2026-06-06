package com.leanmate.stats.application;

import com.leanmate.stats.dto.DailyNutritionSnapshotResponse;
import com.leanmate.stats.repository.DailyNutritionSnapshotEntity;
import com.leanmate.stats.repository.DailyNutritionSnapshotRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class DailyNutritionSnapshotApplicationService {

    private static final BigDecimal ZERO = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);

    private final DailyNutritionSnapshotRepository dailyNutritionSnapshotRepository;

    public DailyNutritionSnapshotApplicationService(
            DailyNutritionSnapshotRepository dailyNutritionSnapshotRepository
    ) {
        this.dailyNutritionSnapshotRepository = dailyNutritionSnapshotRepository;
    }

    public DailyNutritionSnapshotResponse updateWeight(
            UUID userId,
            LocalDate date,
            int calorieTargetKcal,
            BigDecimal weightKg
    ) {
        DailyNutritionSnapshotEntity snapshot = getOrInitialize(userId, date, calorieTargetKcal);
        snapshot.setWeightKg(scaleWeight(weightKg));
        return toResponse(saveWithRecalculatedRemaining(snapshot, calorieTargetKcal));
    }

    public DailyNutritionSnapshotResponse getOrCreateForHome(
            UUID userId,
            LocalDate date,
            int calorieTargetKcal
    ) {
        DailyNutritionSnapshotEntity snapshot = getOrInitialize(userId, date, calorieTargetKcal);
        return toResponse(saveWithRecalculatedRemaining(snapshot, calorieTargetKcal));
    }

    DailyNutritionSnapshotResponse toResponse(DailyNutritionSnapshotEntity snapshot) {
        return new DailyNutritionSnapshotResponse(
                snapshot.getDate(),
                snapshot.getCalorieTargetKcal(),
                snapshot.getCaloriesKcal(),
                snapshot.getRemainingCaloriesKcal(),
                snapshot.getProteinG(),
                snapshot.getFatG(),
                snapshot.getCarbsG(),
                snapshot.getFoodEntryCount(),
                snapshot.getWeightKg());
    }

    private DailyNutritionSnapshotEntity getOrInitialize(UUID userId, LocalDate date, int calorieTargetKcal) {
        return dailyNutritionSnapshotRepository.findByUserIdAndDate(userId, date)
                .orElseGet(() -> initialize(userId, date, calorieTargetKcal));
    }

    private DailyNutritionSnapshotEntity initialize(UUID userId, LocalDate date, int calorieTargetKcal) {
        DailyNutritionSnapshotEntity snapshot = new DailyNutritionSnapshotEntity();
        snapshot.setUserId(userId);
        snapshot.setDate(date);
        snapshot.setCaloriesKcal(0);
        snapshot.setProteinG(ZERO);
        snapshot.setFatG(ZERO);
        snapshot.setCarbsG(ZERO);
        snapshot.setFoodEntryCount(0);
        snapshot.setWeightKg(null);
        snapshot.setCalorieTargetKcal(calorieTargetKcal);
        snapshot.setRemainingCaloriesKcal(calorieTargetKcal);
        return snapshot;
    }

    private DailyNutritionSnapshotEntity saveWithRecalculatedRemaining(
            DailyNutritionSnapshotEntity snapshot,
            int calorieTargetKcal
    ) {
        snapshot.setCalorieTargetKcal(calorieTargetKcal);
        snapshot.setRemainingCaloriesKcal(calorieTargetKcal - snapshot.getCaloriesKcal());
        return dailyNutritionSnapshotRepository.save(snapshot);
    }

    private BigDecimal scaleWeight(BigDecimal value) {
        if (value == null) {
            return null;
        }
        return value.setScale(2, RoundingMode.HALF_UP);
    }
}
