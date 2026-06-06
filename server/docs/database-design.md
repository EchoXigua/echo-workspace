# LeanMate V1.1 数据库设计

## 设计目标

V1.1 数据库设计支撑：

- 跨 iOS、Android、未来 Web 的统一账号和用户数据。
- 用户档案、减脂目标、饮食记录、体重记录、首页统计、AI 日报、连续打卡。
- AI 原始结果和用户确认结果分离，保证业务数据可信。
- 后续 AI 周报、月报、行为洞察和个体减脂模型可以扩展。

## 通用约定

- 数据库：PostgreSQL。
- 主键：`uuid`。
- 时间字段：`timestamptz`，服务端按 UTC 存储。
- 业务日期：`date`，按用户所在时区计算。
- 状态和枚举：V1.1 使用 `text + check constraint`，比 PostgreSQL enum 更方便迭代。
- 金额、体重、营养数据：使用 `numeric`，热量使用 `integer`。
- JSON 扩展字段：使用 `jsonb`，用于 AI 原始输出、行为属性等可变结构。
- 删除策略：核心业务记录优先软删除，保留排查和统计修复能力。

通用字段建议：

```sql
id uuid primary key default gen_random_uuid(),
created_at timestamptz not null default now(),
updated_at timestamptz not null default now()
```

需要启用扩展：

```sql
create extension if not exists pgcrypto;
```

## 表清单

| 表名 | 说明 | V1.1 |
|------|------|------|
| `users` | 用户主体 | 必需 |
| `user_auth_identities` | 第三方登录身份 | 必需 |
| `refresh_tokens` | 刷新令牌 | 建议 |
| `user_profiles` | 用户身体档案 | 必需 |
| `weight_goals` | 减脂目标 | 必需 |
| `food_entries` | 饮食记录 | 必需 |
| `food_items` | 饮食食物项 | 必需 |
| `ai_recognition_tasks` | AI 图片/文本识别任务 | 必需 |
| `weight_entries` | 体重记录 | 必需 |
| `daily_nutrition_snapshots` | 每日营养统计快照 | 必需 |
| `daily_ai_reports` | AI 日报 | 必需 |
| `streaks` | 连续打卡状态 | 必需 |
| `achievements` | 成就和里程碑 | 可选但建议 |

## 核心建表示例

以下 SQL 可作为 Flyway 迁移脚本的初稿。实际进入编码时建议拆成多个迁移文件。

### users

```sql
create table users (
    id uuid primary key default gen_random_uuid(),
    nickname varchar(64),
    avatar_url text,
    status varchar(32) not null default 'active',
    last_login_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint chk_users_status check (status in ('active', 'disabled', 'deleted'))
);
```

### user_auth_identities

```sql
create table user_auth_identities (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    provider varchar(32) not null,
    provider_user_id varchar(128) not null,
    email varchar(255),
    phone varchar(32),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint chk_auth_provider check (provider in ('apple', 'google', 'phone', 'email')),
    constraint uq_auth_provider_user unique (provider, provider_user_id)
);

create index idx_auth_user_id on user_auth_identities(user_id);
```

### refresh_tokens

```sql
create table refresh_tokens (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    token_hash varchar(128) not null,
    device_id varchar(128),
    expires_at timestamptz not null,
    revoked_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_refresh_token_hash unique (token_hash)
);

create index idx_refresh_tokens_user_id on refresh_tokens(user_id);
create index idx_refresh_tokens_expires_at on refresh_tokens(expires_at);
```

### user_profiles

```sql
create table user_profiles (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    gender varchar(16) not null,
    age integer not null,
    height_cm numeric(5,2) not null,
    current_weight_kg numeric(5,2) not null,
    target_weight_kg numeric(5,2) not null,
    activity_level varchar(32) not null,
    timezone varchar(64) not null default 'Asia/Shanghai',
    bmi numeric(5,2) not null,
    bmr_kcal integer not null,
    daily_calorie_target_kcal integer not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_user_profiles_user unique (user_id),
    constraint chk_profile_gender check (gender in ('male', 'female', 'unknown')),
    constraint chk_profile_activity check (activity_level in ('sedentary', 'light', 'moderate', 'active', 'very_active')),
    constraint chk_profile_age check (age between 1 and 120),
    constraint chk_profile_height check (height_cm between 50 and 250),
    constraint chk_profile_weight check (current_weight_kg between 20 and 300 and target_weight_kg between 20 and 300)
);
```

### weight_goals

```sql
create table weight_goals (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    start_weight_kg numeric(5,2) not null,
    target_weight_kg numeric(5,2) not null,
    target_date date,
    daily_calorie_target_kcal integer not null,
    status varchar(32) not null default 'active',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint chk_weight_goals_status check (status in ('active', 'completed', 'cancelled'))
);

create unique index uq_weight_goals_active_user on weight_goals(user_id) where status = 'active';
```

### ai_recognition_tasks

```sql
create table ai_recognition_tasks (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    source_type varchar(16) not null,
    meal_date date,
    meal_type varchar(16),
    input_text text,
    input_image_url text,
    input_object_key text,
    status varchar(32) not null default 'pending',
    model_name varchar(128),
    raw_output jsonb,
    structured_result jsonb,
    error_code varchar(64),
    error_message text,
    started_at timestamptz,
    finished_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint chk_ai_task_source check (source_type in ('photo', 'text')),
    constraint chk_ai_task_status check (status in ('pending', 'running', 'succeeded', 'failed')),
    constraint chk_ai_task_meal_type check (meal_type is null or meal_type in ('breakfast', 'lunch', 'dinner', 'snack'))
);

create index idx_ai_tasks_user_created on ai_recognition_tasks(user_id, created_at desc);
create index idx_ai_tasks_status_created on ai_recognition_tasks(status, created_at);
```

### food_entries

```sql
create table food_entries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    recognition_task_id uuid references ai_recognition_tasks(id),
    meal_date date not null,
    meal_type varchar(16) not null,
    source_type varchar(16) not null,
    raw_text text,
    image_url text,
    image_object_key text,
    status varchar(32) not null default 'confirmed',
    total_calories_kcal integer not null default 0,
    total_protein_g numeric(8,2) not null default 0,
    total_fat_g numeric(8,2) not null default 0,
    total_carbs_g numeric(8,2) not null default 0,
    confirmed_at timestamptz,
    deleted_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint chk_food_entry_meal_type check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
    constraint chk_food_entry_source check (source_type in ('photo', 'text', 'manual')),
    constraint chk_food_entry_status check (status in ('draft', 'confirmed', 'deleted'))
);

create index idx_food_entries_user_date on food_entries(user_id, meal_date, status);
create index idx_food_entries_recognition_task on food_entries(recognition_task_id);
```

### food_items

```sql
create table food_items (
    id uuid primary key default gen_random_uuid(),
    food_entry_id uuid not null references food_entries(id),
    name varchar(128) not null,
    quantity_text varchar(128),
    weight_g numeric(8,2),
    calories_kcal integer,
    protein_g numeric(8,2),
    fat_g numeric(8,2),
    carbs_g numeric(8,2),
    confidence numeric(5,4),
    is_user_edited boolean not null default false,
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_food_items_entry on food_items(food_entry_id, sort_order);
```

### weight_entries

```sql
create table weight_entries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    record_date date not null,
    weight_kg numeric(5,2) not null,
    note text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_weight_entries_user_date unique (user_id, record_date),
    constraint chk_weight_entries_weight check (weight_kg between 20 and 300)
);

create index idx_weight_entries_user_date on weight_entries(user_id, record_date desc);
```

### daily_nutrition_snapshots

```sql
create table daily_nutrition_snapshots (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    date date not null,
    calorie_target_kcal integer not null,
    calories_kcal integer not null default 0,
    protein_g numeric(8,2) not null default 0,
    fat_g numeric(8,2) not null default 0,
    carbs_g numeric(8,2) not null default 0,
    remaining_calories_kcal integer not null default 0,
    food_entry_count integer not null default 0,
    weight_kg numeric(5,2),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_daily_snapshots_user_date unique (user_id, date)
);

create index idx_daily_snapshots_user_date on daily_nutrition_snapshots(user_id, date desc);
```

### daily_ai_reports

```sql
create table daily_ai_reports (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    snapshot_id uuid references daily_nutrition_snapshots(id),
    report_date date not null,
    status varchar(32) not null default 'pending',
    score integer,
    summary text,
    problem text,
    suggestion text,
    raw_output jsonb,
    error_code varchar(64),
    error_message text,
    generated_at timestamptz,
    viewed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_daily_reports_user_date unique (user_id, report_date),
    constraint chk_daily_report_status check (status in ('pending', 'generated', 'viewed', 'failed')),
    constraint chk_daily_report_score check (score is null or score between 0 and 100)
);

create index idx_daily_reports_user_date on daily_ai_reports(user_id, report_date desc);
```

### streaks

```sql
create table streaks (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    current_days integer not null default 0,
    longest_days integer not null default 0,
    last_active_date date,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_streaks_user unique (user_id),
    constraint chk_streak_days check (current_days >= 0 and longest_days >= 0)
);
```

### achievements

```sql
create table achievements (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    type varchar(64) not null,
    achieved_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    constraint uq_achievements_user_type unique (user_id, type),
    constraint chk_achievement_type check (type in ('streak_3', 'streak_7', 'streak_30', 'streak_100', 'goal_reached'))
);

create index idx_achievements_user on achievements(user_id, achieved_at desc);
```

## 统计刷新策略

`daily_nutrition_snapshots` 是首页和日报的主要读取模型。

触发刷新：

- 饮食记录 confirmed。
- 饮食记录编辑。
- 饮食记录删除。
- 体重记录创建或覆盖。
- 用户目标更新。

刷新方式：

- V1.1 可在同一事务内同步重算当日快照。
- 如果后续写入压力变大，再改为异步刷新。

## 软删除和审计

V1.1 只对饮食记录做软删除：

- `food_entries.status = deleted`
- `food_entries.deleted_at`

`food_items` 不单独删除，跟随 `food_entries` 聚合读取。

用户删除账号、隐私合规和数据导出后续需要单独设计。

## 待确认问题

- V1.1 首发登录方式是否只做 Apple 登录。
- 日报生成失败是否需要独立 job 表，还是先复用 `daily_ai_reports.status`。
- 图片保存期限和删除策略。
- 用户本地时区是否只保存在 `user_profiles.timezone`。
