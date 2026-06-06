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
