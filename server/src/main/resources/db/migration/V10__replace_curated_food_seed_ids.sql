create temporary table food_seed_id_map (
    old_id uuid primary key,
    new_id uuid not null unique
) on commit drop;

insert into food_seed_id_map (old_id, new_id) values
('10000000-0000-0000-0000-000000000001', 'ae5064cd-b812-4df7-bc0d-22634e99356e'),
('10000000-0000-0000-0000-000000000002', '9ab97e07-4ea9-43d9-b68a-73efef385d62'),
('10000000-0000-0000-0000-000000000003', 'a469c3ad-47c9-4dd7-99ab-7bfd415ed347'),
('10000000-0000-0000-0000-000000000004', '0a1b8ef0-6ec2-429e-b615-2da2b3463af3'),
('10000000-0000-0000-0000-000000000005', '8b32eeb1-5b74-42a7-a02a-1697e23cc935'),
('10000000-0000-0000-0000-000000000006', 'ea6381d6-58ae-4e6b-8c4f-962b50dcdb18'),
('10000000-0000-0000-0000-000000000007', '991ca9d0-8b2b-4f4c-b08d-7ecbc5fd0527'),
('10000000-0000-0000-0000-000000000008', '4c1a4327-b418-44ef-893f-725d090e856a'),
('10000000-0000-0000-0000-000000000009', '73fba9fd-ac02-41ae-838e-3ab0c029634d'),
('10000000-0000-0000-0000-000000000010', 'a658137a-35a4-4278-8a1f-745edcc7db9b'),
('10000000-0000-0000-0000-000000000011', 'f1cfb2fc-a61f-497c-b9a6-843c06b1b428'),
('10000000-0000-0000-0000-000000000012', '9598e0fe-99ed-4b50-b598-cb7802b68035'),
('10000000-0000-0000-0000-000000000013', '20af1809-7d51-4dc5-9537-595bdeb716bf'),
('10000000-0000-0000-0000-000000000014', '364684bb-71c5-46ef-ba0b-ba709d73a0f2'),
('10000000-0000-0000-0000-000000000015', '917501f8-4a66-40c0-8813-27b91bf42176'),
('10000000-0000-0000-0000-000000000016', 'a4f40172-4c42-430e-a3e3-9cd6bd48b51a'),
('10000000-0000-0000-0000-000000000017', 'a9139f95-8fe7-4bb4-b790-4ae659ada44c'),
('10000000-0000-0000-0000-000000000018', '144f087d-7617-410e-ba5a-866c998da998'),
('10000000-0000-0000-0000-000000000019', '3f0e223f-84e6-416f-9402-f8f553b5c5e0'),
('10000000-0000-0000-0000-000000000020', 'aeda8c20-2767-44e4-b3fa-8c3f60dc0eba');

create temporary table food_portion_seed_id_map (
    old_id uuid primary key,
    new_id uuid not null unique
) on commit drop;

insert into food_portion_seed_id_map (old_id, new_id) values
('20000000-0000-0000-0000-000000000001', '02804b3a-376f-4e6f-8eb0-1e6ae3554d50'),
('20000000-0000-0000-0000-000000000002', 'a540e0e0-a11f-44fe-9113-dbe958fcd382'),
('20000000-0000-0000-0000-000000000003', '7123279e-cfa0-4c53-8ee3-aa8f80ada946'),
('20000000-0000-0000-0000-000000000004', 'e4126969-3aaf-445e-82ed-1244428673a1'),
('20000000-0000-0000-0000-000000000005', '4fef6988-50b4-4515-b850-3a53bc9c488f'),
('20000000-0000-0000-0000-000000000006', 'af76d162-4133-4e1c-b466-4387e999fe1e'),
('20000000-0000-0000-0000-000000000007', '963fd181-2dc8-44a3-bf5c-ded8fd36b30b'),
('20000000-0000-0000-0000-000000000008', 'acac53e1-f9d2-406f-983c-2cbb3a4af048'),
('20000000-0000-0000-0000-000000000009', '3d06cd66-b1c3-48cd-8291-fdb297a0fa1d'),
('20000000-0000-0000-0000-000000000010', 'c74ad3d5-f029-4ceb-befe-2fb0dc0e3f5e'),
('20000000-0000-0000-0000-000000000011', 'd1bc7ac9-8c26-4636-abad-f15111fa363f'),
('20000000-0000-0000-0000-000000000012', '93cadb62-f1f1-4e20-9610-c97fff6d14e3'),
('20000000-0000-0000-0000-000000000013', '26584ba9-606c-4e29-9c22-56f1202454eb'),
('20000000-0000-0000-0000-000000000014', 'e75a27fc-09cf-4b1f-9b3e-362a5b589bbd'),
('20000000-0000-0000-0000-000000000015', '7e74bb97-36ea-42c4-a8e0-62ca7ad4ce5b'),
('20000000-0000-0000-0000-000000000016', '67cf07e7-a2b4-4933-9787-47f98a511989'),
('20000000-0000-0000-0000-000000000017', '1d9fba1f-2f74-4ced-a90d-e733eddf8b1b'),
('20000000-0000-0000-0000-000000000018', '7d95032f-51b4-4e7a-a5b3-777d140d1613'),
('20000000-0000-0000-0000-000000000019', '5505bd46-33af-4fc5-882c-a96f07dd04d7'),
('20000000-0000-0000-0000-000000000020', '43f2292b-d1ab-488c-9960-dd14f726dcd7'),
('20000000-0000-0000-0000-000000000021', 'c6107c6a-b286-481d-95b4-94124910f29a');

alter table food_aliases drop constraint if exists food_aliases_food_id_fkey;
alter table food_portions drop constraint if exists food_portions_food_id_fkey;
alter table food_items drop constraint if exists food_items_food_catalog_id_fkey;

update food_aliases alias
set food_id = id_map.new_id
from food_seed_id_map id_map
where alias.food_id = id_map.old_id;

update food_portions portion
set food_id = id_map.new_id
from food_seed_id_map id_map
where portion.food_id = id_map.old_id;

update food_items item
set food_catalog_id = id_map.new_id
from food_seed_id_map id_map
where item.food_catalog_id = id_map.old_id;

update food_catalog food
set id = id_map.new_id,
    updated_at = now()
from food_seed_id_map id_map
where food.id = id_map.old_id;

update food_portions portion
set id = id_map.new_id
from food_portion_seed_id_map id_map
where portion.id = id_map.old_id;

alter table food_aliases
    add constraint food_aliases_food_id_fkey
    foreign key (food_id) references food_catalog(id);

alter table food_portions
    add constraint food_portions_food_id_fkey
    foreign key (food_id) references food_catalog(id);

alter table food_items
    add constraint food_items_food_catalog_id_fkey
    foreign key (food_catalog_id) references food_catalog(id);
