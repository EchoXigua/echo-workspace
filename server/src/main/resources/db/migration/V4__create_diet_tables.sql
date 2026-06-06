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
