package com.leanmate.food.seed;

import com.leanmate.food.domain.FoodCatalogSource;
import com.leanmate.food.repository.FoodAliasEntity;
import com.leanmate.food.repository.FoodAliasRepository;
import com.leanmate.food.repository.FoodCatalogEntity;
import com.leanmate.food.repository.FoodCatalogRepository;
import com.leanmate.food.repository.FoodPortionEntity;
import com.leanmate.food.repository.FoodPortionRepository;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class FoodCatalogSeedService {

    private static final Logger log = LoggerFactory.getLogger(FoodCatalogSeedService.class);

    private final ResourceLoader resourceLoader;
    private final FoodCatalogRepository foodCatalogRepository;
    private final FoodAliasRepository foodAliasRepository;
    private final FoodPortionRepository foodPortionRepository;

    public FoodCatalogSeedService(
            ResourceLoader resourceLoader,
            FoodCatalogRepository foodCatalogRepository,
            FoodAliasRepository foodAliasRepository,
            FoodPortionRepository foodPortionRepository
    ) {
        this.resourceLoader = resourceLoader;
        this.foodCatalogRepository = foodCatalogRepository;
        this.foodAliasRepository = foodAliasRepository;
        this.foodPortionRepository = foodPortionRepository;
    }

    @Transactional
    public void importSeed(String location) {
        String root = trimTrailingSlash(location);
        List<FoodSeedRow> foods = readFoods(root + "/foods.csv");
        List<FoodAliasSeedRow> aliases = readAliases(root + "/aliases.csv");
        List<FoodPortionSeedRow> portions = readPortions(root + "/portions.csv");
        validateSeed(foods, aliases, portions);

        Map<UUID, List<FoodAliasSeedRow>> aliasesByFood = aliases.stream()
                .collect(Collectors.groupingBy(FoodAliasSeedRow::foodId));
        Map<UUID, List<FoodPortionSeedRow>> portionsByFood = portions.stream()
                .collect(Collectors.groupingBy(FoodPortionSeedRow::foodId));

        for (FoodSeedRow seed : foods) {
            FoodCatalogEntity food = foodCatalogRepository.findById(seed.id())
                    .orElseGet(FoodCatalogEntity::new);
            food.setId(seed.id());
            food.setName(seed.name());
            food.setNormalizedName(normalize(seed.name()));
            food.setCategory(seed.category());
            food.setCaloriesPer100g(seed.caloriesPer100g());
            food.setProteinPer100g(seed.proteinPer100g());
            food.setFatPer100g(seed.fatPer100g());
            food.setCarbsPer100g(seed.carbsPer100g());
            food.setSource(seed.source().value());
            food.setConfidence(seed.confidence());
            food.setVerified(seed.verified());
            food.setLocale(seed.locale());
            foodCatalogRepository.save(food);

            foodAliasRepository.deleteByFoodId(seed.id());
            foodAliasRepository.saveAll(aliasesByFood.getOrDefault(seed.id(), List.of())
                    .stream()
                    .map(this::toAliasEntity)
                    .toList());

            foodPortionRepository.deleteByFoodId(seed.id());
            foodPortionRepository.saveAll(portionsByFood.getOrDefault(seed.id(), List.of())
                    .stream()
                    .map(this::toPortionEntity)
                    .toList());
        }

        log.info("食物基础库 CSV 导入完成 foods={}, aliases={}, portions={}",
                foods.size(),
                aliases.size(),
                portions.size());
    }

    private List<FoodSeedRow> readFoods(String location) {
        return readCsv(location).stream()
                .map(row -> new FoodSeedRow(
                        uuid(row, "id"),
                        required(row, "name"),
                        required(row, "category"),
                        integer(row, "caloriesPer100g"),
                        decimal(row, "proteinPer100g"),
                        decimal(row, "fatPer100g"),
                        decimal(row, "carbsPer100g"),
                        FoodCatalogSource.fromValue(required(row, "source")),
                        decimal(row, "confidence"),
                        bool(row, "verified"),
                        optional(row, "locale", "zh-CN")))
                .toList();
    }

    private List<FoodAliasSeedRow> readAliases(String location) {
        return readCsv(location).stream()
                .map(row -> new FoodAliasSeedRow(
                        uuid(row, "foodId"),
                        required(row, "alias"),
                        optional(row, "locale", "zh-CN")))
                .toList();
    }

    private List<FoodPortionSeedRow> readPortions(String location) {
        return readCsv(location).stream()
                .map(row -> new FoodPortionSeedRow(
                        uuid(row, "id"),
                        uuid(row, "foodId"),
                        required(row, "label"),
                        decimal(row, "gramWeight"),
                        bool(row, "defaultPortion"),
                        integer(row, "sortOrder")))
                .toList();
    }

    private List<Map<String, String>> readCsv(String location) {
        Resource resource = resourceLoader.getResource(location);
        if (!resource.exists()) {
            throw new IllegalStateException("食物基础库文件不存在: " + location);
        }
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                resource.getInputStream(),
                StandardCharsets.UTF_8))) {
            String headerLine = nextDataLine(reader);
            if (headerLine == null) {
                return List.of();
            }
            List<String> headers = parseCsvLine(headerLine);
            List<Map<String, String>> rows = new ArrayList<>();
            String line;
            int lineNumber = 1;
            while ((line = reader.readLine()) != null) {
                lineNumber++;
                if (!StringUtils.hasText(line) || line.trim().startsWith("#")) {
                    continue;
                }
                List<String> values = parseCsvLine(line);
                if (values.size() != headers.size()) {
                    throw new IllegalStateException("%s 第 %d 行字段数不匹配".formatted(location, lineNumber));
                }
                Map<String, String> row = new LinkedHashMap<>();
                for (int i = 0; i < headers.size(); i++) {
                    row.put(headers.get(i), values.get(i));
                }
                rows.add(row);
            }
            return rows;
        } catch (IOException exception) {
            throw new IllegalStateException("读取食物基础库文件失败: " + location, exception);
        }
    }

    private String nextDataLine(BufferedReader reader) throws IOException {
        String line;
        while ((line = reader.readLine()) != null) {
            if (StringUtils.hasText(line) && !line.trim().startsWith("#")) {
                return line;
            }
        }
        return null;
    }

    private List<String> parseCsvLine(String line) {
        List<String> values = new ArrayList<>();
        StringBuilder value = new StringBuilder();
        boolean quoted = false;
        for (int i = 0; i < line.length(); i++) {
            char ch = line.charAt(i);
            if (ch == '"') {
                if (quoted && i + 1 < line.length() && line.charAt(i + 1) == '"') {
                    value.append('"');
                    i++;
                } else {
                    quoted = !quoted;
                }
            } else if (ch == ',' && !quoted) {
                values.add(value.toString().trim());
                value.setLength(0);
            } else {
                value.append(ch);
            }
        }
        if (quoted) {
            throw new IllegalStateException("CSV 引号未闭合");
        }
        values.add(value.toString().trim());
        return values;
    }

    private void validateSeed(
            List<FoodSeedRow> foods,
            List<FoodAliasSeedRow> aliases,
            List<FoodPortionSeedRow> portions
    ) {
        Set<UUID> foodIds = new HashSet<>();
        Set<String> localeNames = new HashSet<>();
        for (FoodSeedRow food : foods) {
            requireUnique(foodIds.add(food.id()), "重复的食物 id: " + food.id());
            requireUnique(localeNames.add(food.locale() + ":" + normalize(food.name())),
                    "重复的食物名称: " + food.name());
            requireRange(food.caloriesPer100g() >= 0 && food.caloriesPer100g() <= 1000,
                    "caloriesPer100g 超出范围: " + food.name());
            requireRange(inRange(food.proteinPer100g(), "0", "1000"), "proteinPer100g 超出范围: " + food.name());
            requireRange(inRange(food.fatPer100g(), "0", "1000"), "fatPer100g 超出范围: " + food.name());
            requireRange(inRange(food.carbsPer100g(), "0", "1000"), "carbsPer100g 超出范围: " + food.name());
            requireRange(inRange(food.confidence(), "0", "1"), "confidence 必须在 0-1: " + food.name());
        }

        Set<String> aliasKeys = new HashSet<>();
        for (FoodAliasSeedRow alias : aliases) {
            requireReference(foodIds.contains(alias.foodId()), "别名引用了不存在的 foodId: " + alias.foodId());
            requireUnique(aliasKeys.add(alias.foodId() + ":" + alias.locale() + ":" + normalize(alias.alias())),
                    "重复的食物别名: " + alias.alias());
        }

        Set<UUID> portionIds = new HashSet<>();
        Map<UUID, Integer> defaultPortionCounts = new HashMap<>();
        for (FoodPortionSeedRow portion : portions) {
            requireUnique(portionIds.add(portion.id()), "重复的份量 id: " + portion.id());
            requireReference(foodIds.contains(portion.foodId()), "份量引用了不存在的 foodId: " + portion.foodId());
            requireRange(inRange(portion.gramWeight(), "0.01", "10000"), "gramWeight 超出范围: " + portion.label());
            if (portion.defaultPortion()) {
                defaultPortionCounts.merge(portion.foodId(), 1, Integer::sum);
            }
        }
        defaultPortionCounts.forEach((foodId, count) -> requireUnique(count == 1,
                "同一个食物只能有一个默认份量: " + foodId));
    }

    private FoodAliasEntity toAliasEntity(FoodAliasSeedRow seed) {
        FoodAliasEntity alias = new FoodAliasEntity();
        alias.setFoodId(seed.foodId());
        alias.setAlias(seed.alias());
        alias.setNormalizedAlias(normalize(seed.alias()));
        alias.setLocale(seed.locale());
        return alias;
    }

    private FoodPortionEntity toPortionEntity(FoodPortionSeedRow seed) {
        FoodPortionEntity portion = new FoodPortionEntity();
        portion.setId(seed.id());
        portion.setFoodId(seed.foodId());
        portion.setLabel(seed.label());
        portion.setGramWeight(seed.gramWeight());
        portion.setDefaultPortion(seed.defaultPortion());
        portion.setSortOrder(seed.sortOrder());
        return portion;
    }

    private String required(Map<String, String> row, String field) {
        String value = row.get(field);
        if (!StringUtils.hasText(value)) {
            throw new IllegalStateException("食物基础库字段不能为空: " + field);
        }
        return value.trim();
    }

    private String optional(Map<String, String> row, String field, String defaultValue) {
        String value = row.get(field);
        return StringUtils.hasText(value) ? value.trim() : defaultValue;
    }

    private UUID uuid(Map<String, String> row, String field) {
        return UUID.fromString(required(row, field));
    }

    private Integer integer(Map<String, String> row, String field) {
        return Integer.valueOf(required(row, field));
    }

    private BigDecimal decimal(Map<String, String> row, String field) {
        return new BigDecimal(required(row, field));
    }

    private boolean bool(Map<String, String> row, String field) {
        String value = required(row, field).toLowerCase();
        if (!"true".equals(value) && !"false".equals(value)) {
            throw new IllegalStateException("食物基础库布尔字段只能是 true/false: " + field);
        }
        return Boolean.parseBoolean(value);
    }

    private boolean inRange(BigDecimal value, String min, String max) {
        return value.compareTo(new BigDecimal(min)) >= 0 && value.compareTo(new BigDecimal(max)) <= 0;
    }

    private void requireUnique(boolean valid, String message) {
        if (!valid) {
            throw new IllegalStateException(message);
        }
    }

    private void requireReference(boolean valid, String message) {
        if (!valid) {
            throw new IllegalStateException(message);
        }
    }

    private void requireRange(boolean valid, String message) {
        if (!valid) {
            throw new IllegalStateException(message);
        }
    }

    private String normalize(String value) {
        if (value == null) {
            return "";
        }
        return value.trim().toLowerCase().replaceAll("\\s+", "");
    }

    private String trimTrailingSlash(String value) {
        return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }

    private record FoodSeedRow(
            UUID id,
            String name,
            String category,
            Integer caloriesPer100g,
            BigDecimal proteinPer100g,
            BigDecimal fatPer100g,
            BigDecimal carbsPer100g,
            FoodCatalogSource source,
            BigDecimal confidence,
            Boolean verified,
            String locale
    ) {
    }

    private record FoodAliasSeedRow(
            UUID foodId,
            String alias,
            String locale
    ) {
    }

    private record FoodPortionSeedRow(
            UUID id,
            UUID foodId,
            String label,
            BigDecimal gramWeight,
            Boolean defaultPortion,
            Integer sortOrder
    ) {
    }
}
