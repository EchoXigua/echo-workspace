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
