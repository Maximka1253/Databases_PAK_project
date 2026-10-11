select
    row_number() over (order by table_name) as "№",
    table_name as "Наименование",
    'Таблица' as "Тип"
from information_schema.tables
where table_schema = 'public'
    and table_type = 'BASE TABLE'
order by table_name;