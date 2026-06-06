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
