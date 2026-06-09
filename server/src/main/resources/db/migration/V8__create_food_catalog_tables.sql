create table food_catalog (
    id uuid primary key default gen_random_uuid(),
    name varchar(128) not null,
    normalized_name varchar(128) not null,
    category varchar(64) not null,
    calories_per_100g integer not null,
    protein_per_100g numeric(8,2) not null default 0,
    fat_per_100g numeric(8,2) not null default 0,
    carbs_per_100g numeric(8,2) not null default 0,
    source varchar(32) not null,
    confidence numeric(5,4) not null default 1.0,
    verified boolean not null default false,
    locale varchar(16) not null default 'zh-CN',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_food_catalog_locale_normalized_name unique (locale, normalized_name),
    constraint chk_food_catalog_calories check (calories_per_100g between 0 and 1000),
    constraint chk_food_catalog_protein check (protein_per_100g between 0 and 1000),
    constraint chk_food_catalog_fat check (fat_per_100g between 0 and 1000),
    constraint chk_food_catalog_carbs check (carbs_per_100g between 0 and 1000),
    constraint chk_food_catalog_source check (source in ('curated', 'usda', 'open_food_facts', 'vendor', 'ai_estimated'))
);

create index idx_food_catalog_normalized_name on food_catalog(normalized_name);
create index idx_food_catalog_category on food_catalog(category);

create table food_aliases (
    id uuid primary key default gen_random_uuid(),
    food_id uuid not null references food_catalog(id),
    alias varchar(128) not null,
    normalized_alias varchar(128) not null,
    locale varchar(16) not null default 'zh-CN',
    created_at timestamptz not null default now(),
    constraint uq_food_aliases_food_alias unique (food_id, locale, normalized_alias)
);

create index idx_food_aliases_normalized_alias on food_aliases(normalized_alias);
create index idx_food_aliases_food on food_aliases(food_id);

create table food_portions (
    id uuid primary key default gen_random_uuid(),
    food_id uuid not null references food_catalog(id),
    label varchar(128) not null,
    gram_weight numeric(8,2) not null,
    is_default boolean not null default false,
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    constraint chk_food_portions_weight check (gram_weight > 0 and gram_weight <= 10000)
);

create index idx_food_portions_food on food_portions(food_id, sort_order);
create unique index uq_food_portions_default
    on food_portions(food_id)
    where is_default = true;

alter table food_items
    add column food_catalog_id uuid references food_catalog(id),
    add column nutrition_source varchar(32);

alter table food_items
    add constraint chk_food_items_nutrition_source
        check (nutrition_source is null or nutrition_source in ('food_db', 'ai_estimated', 'user_confirmed', 'user_override'));

create index idx_food_items_catalog on food_items(food_catalog_id);

insert into food_catalog (
    id,
    name,
    normalized_name,
    category,
    calories_per_100g,
    protein_per_100g,
    fat_per_100g,
    carbs_per_100g,
    source,
    confidence,
    verified
) values
('10000000-0000-0000-0000-000000000001', '米饭', '米饭', 'staple', 116, 2.60, 0.30, 25.90, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000002', '面条', '面条', 'staple', 138, 4.50, 1.00, 28.00, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000003', '馒头', '馒头', 'staple', 223, 7.00, 1.10, 47.00, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000004', '鸡蛋', '鸡蛋', 'protein', 143, 12.60, 9.50, 0.70, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000005', '鸡胸肉', '鸡胸肉', 'protein', 165, 31.00, 3.60, 0.00, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000006', '牛肉', '牛肉', 'protein', 250, 26.00, 15.00, 0.00, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000007', '豆腐', '豆腐', 'protein', 76, 8.00, 4.80, 1.90, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000008', '西兰花', '西兰花', 'vegetable', 34, 2.80, 0.40, 6.60, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000009', '番茄', '番茄', 'vegetable', 18, 0.90, 0.20, 3.90, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000010', '黄瓜', '黄瓜', 'vegetable', 15, 0.70, 0.10, 3.60, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000011', '苹果', '苹果', 'fruit', 52, 0.30, 0.20, 13.80, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000012', '香蕉', '香蕉', 'fruit', 89, 1.10, 0.30, 22.80, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000013', '橙子', '橙子', 'fruit', 47, 0.90, 0.10, 11.80, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000014', '牛奶', '牛奶', 'drink', 54, 3.20, 3.30, 4.80, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000015', '豆浆', '豆浆', 'drink', 31, 3.00, 1.60, 1.20, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000016', '美式咖啡', '美式咖啡', 'drink', 2, 0.10, 0.00, 0.00, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000017', '拿铁', '拿铁', 'drink', 48, 3.10, 2.00, 4.80, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000018', '坚果', '坚果', 'snack', 607, 20.00, 54.00, 21.00, 'curated', 1.0, true),
('10000000-0000-0000-0000-000000000019', '沙拉', '沙拉', 'dish', 70, 3.00, 4.00, 6.00, 'curated', 0.8, true),
('10000000-0000-0000-0000-000000000020', '黄焖鸡', '黄焖鸡', 'dish', 165, 13.00, 9.00, 8.00, 'curated', 0.7, true);

insert into food_aliases (food_id, alias, normalized_alias) values
('10000000-0000-0000-0000-000000000001', '白饭', '白饭'),
('10000000-0000-0000-0000-000000000001', '米饭', '米饭'),
('10000000-0000-0000-0000-000000000004', '水煮蛋', '水煮蛋'),
('10000000-0000-0000-0000-000000000005', '鸡胸', '鸡胸'),
('10000000-0000-0000-0000-000000000008', '西蓝花', '西蓝花'),
('10000000-0000-0000-0000-000000000009', '西红柿', '西红柿'),
('10000000-0000-0000-0000-000000000011', '红富士', '红富士'),
('10000000-0000-0000-0000-000000000016', '黑咖啡', '黑咖啡'),
('10000000-0000-0000-0000-000000000017', '咖啡拿铁', '咖啡拿铁');

insert into food_portions (id, food_id, label, gram_weight, is_default, sort_order) values
('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '1碗', 200, true, 0),
('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', '1碗', 250, true, 0),
('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', '1个', 100, true, 0),
('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000004', '1个', 50, true, 0),
('20000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000005', '1掌心', 150, true, 0),
('20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000006', '1份', 150, true, 0),
('20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000007', '1块', 100, true, 0),
('20000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000008', '1碗', 150, true, 0),
('20000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000009', '1个', 150, true, 0),
('20000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000010', '1根', 150, true, 0),
('20000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000011', '1个中等大小', 180, true, 0),
('20000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000011', '半个', 90, false, 1),
('20000000-0000-0000-0000-000000000013', '10000000-0000-0000-0000-000000000012', '1根', 120, true, 0),
('20000000-0000-0000-0000-000000000014', '10000000-0000-0000-0000-000000000013', '1个', 150, true, 0),
('20000000-0000-0000-0000-000000000015', '10000000-0000-0000-0000-000000000014', '1杯', 250, true, 0),
('20000000-0000-0000-0000-000000000016', '10000000-0000-0000-0000-000000000015', '1杯', 250, true, 0),
('20000000-0000-0000-0000-000000000017', '10000000-0000-0000-0000-000000000016', '1杯', 300, true, 0),
('20000000-0000-0000-0000-000000000018', '10000000-0000-0000-0000-000000000017', '1杯', 300, true, 0),
('20000000-0000-0000-0000-000000000019', '10000000-0000-0000-0000-000000000018', '1小把', 30, true, 0),
('20000000-0000-0000-0000-000000000020', '10000000-0000-0000-0000-000000000019', '1份', 300, true, 0),
('20000000-0000-0000-0000-000000000021', '10000000-0000-0000-0000-000000000020', '1份', 400, true, 0);
