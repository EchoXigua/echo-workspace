alter table weight_goals
    add column goal_type varchar(32) not null default 'lose_weight',
    add column weekly_target_weight_change_kg numeric(5,2);

alter table weight_goals
    add constraint chk_weight_goals_goal_type
        check (goal_type in ('lose_weight', 'gain_weight', 'maintain'));

alter table achievements
    drop constraint chk_achievement_type;

alter table achievements
    add constraint chk_achievement_type
        check (type in ('streak_3', 'streak_7', 'streak_12', 'streak_30', 'streak_100', 'goal_reached'));

alter table weight_entries
    add column client_local_id uuid;

create unique index uq_weight_entries_user_client_local
    on weight_entries(user_id, client_local_id)
    where client_local_id is not null;

create table retention_notices (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    type varchar(64) not null,
    milestone_value integer not null,
    title varchar(128) not null,
    message text,
    status varchar(32) not null default 'pending',
    triggered_at timestamptz not null default now(),
    dismissed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_retention_notices_user_type_value unique (user_id, type, milestone_value),
    constraint chk_retention_notices_status check (status in ('pending', 'dismissed'))
);

create index idx_retention_notices_user_status
    on retention_notices(user_id, status, triggered_at desc);

create table user_settings (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id),
    meal_reminder_enabled boolean not null default false,
    meal_reminder_times jsonb not null default '[]'::jsonb,
    milestone_notice_enabled boolean not null default true,
    auto_sync_enabled boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_user_settings_user unique (user_id)
);
