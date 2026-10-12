select
    row_number() over (order by t.name) as "№",
    t.name as "Наименование",
    t.type as "Тип"
from (
    -- Таблицы
    select
        table_name as name,
        'Таблица' as type
    from information_schema.tables
    where table_schema = 'public'
      and table_catalog = current_database()

    union all

    -- Счетчики
    select
        sequence_name as name,
        'Счетчик' as type
    from information_schema.sequences
    where sequence_schema = 'public'
      and sequence_catalog = current_database()
) as t
order by t.name;