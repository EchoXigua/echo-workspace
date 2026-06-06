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
