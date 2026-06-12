update food_portions
set label = '一杯（约250ml）'
where id in (
    '7e74bb97-36ea-42c4-a8e0-62ca7ad4ce5b',
    '67cf07e7-a2b4-4933-9787-47f98a511989'
);

update food_portions
set label = '一杯（约300ml）'
where id in (
    '1d9fba1f-2f74-4ced-a90d-e733eddf8b1b',
    '7d95032f-51b4-4e7a-a5b3-777d140d1613'
);
