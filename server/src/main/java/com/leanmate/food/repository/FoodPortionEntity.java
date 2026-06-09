package com.leanmate.food.repository;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "food_portions")
public class FoodPortionEntity {

    @Id
    private UUID id;

    @Column(name = "food_id", nullable = false)
    private UUID foodId;

    @Column(name = "label", nullable = false, length = 128)
    private String label;

    @Column(name = "gram_weight", nullable = false, precision = 8, scale = 2)
    private BigDecimal gramWeight;

    @Column(name = "is_default", nullable = false)
    private Boolean defaultPortion;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (id == null) {
            id = UUID.randomUUID();
        }
        createdAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getFoodId() {
        return foodId;
    }

    public void setFoodId(UUID foodId) {
        this.foodId = foodId;
    }

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public BigDecimal getGramWeight() {
        return gramWeight;
    }

    public void setGramWeight(BigDecimal gramWeight) {
        this.gramWeight = gramWeight;
    }

    public Boolean getDefaultPortion() {
        return defaultPortion;
    }

    public void setDefaultPortion(Boolean defaultPortion) {
        this.defaultPortion = defaultPortion;
    }

    public Integer getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(Integer sortOrder) {
        this.sortOrder = sortOrder;
    }
}
