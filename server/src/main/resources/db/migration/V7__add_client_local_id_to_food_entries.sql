alter table food_entries
    add column client_local_id uuid;

create unique index uq_food_entries_user_client_local_id
    on food_entries(user_id, client_local_id)
    where client_local_id is not null;
