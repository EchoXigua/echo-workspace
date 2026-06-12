create table ai_model_call_logs (
    id uuid primary key default gen_random_uuid(),
    request_id varchar(64),
    user_id uuid references users(id),
    business_type varchar(64) not null,
    business_id uuid,
    provider varchar(64) not null,
    requested_model varchar(128),
    response_model varchar(128),
    prompt_version varchar(64),
    status varchar(32) not null,
    http_status integer,
    provider_error_code varchar(128),
    error_message text,
    prompt_tokens integer,
    completion_tokens integer,
    total_tokens integer,
    estimated_cost_minor integer,
    duration_ms bigint,
    attempt integer not null default 1,
    created_at timestamptz not null default now(),
    constraint chk_ai_model_call_logs_status check (status in ('succeeded', 'failed', 'timeout', 'invalid_response')),
    constraint chk_ai_model_call_logs_attempt check (attempt >= 1)
);

create index idx_ai_model_call_logs_user_created on ai_model_call_logs(user_id, created_at desc);
create index idx_ai_model_call_logs_business on ai_model_call_logs(business_type, business_id);
create index idx_ai_model_call_logs_provider_model_created
    on ai_model_call_logs(provider, requested_model, created_at desc);
create index idx_ai_model_call_logs_status_created on ai_model_call_logs(status, created_at desc);
