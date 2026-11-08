drop function if exists test_meteo;

-- Функция для отображение расчетов в таблице
create or replace function test_meteo(
    p_params parameter_value[],
    p_mode int
) returns setof meteo_height_result
language plpgsql as $$
declare
    v meteo_height_result[];
begin
    call calculate_meteo_heights(p_params, p_mode, v);
    return query select * from unnest(v);
end $$;


-- Пример 1
select h as "H", tt as "TT", hh as "HH", cc as "CC"
from test_meteo(array[
    row(1,100)::parameter_value,
    row(2,23.0)::parameter_value,
    row(3,750)::parameter_value,
    row(4,0)::parameter_value,
    row(5,0)::parameter_value
], 1);

-- Пример 2
select h as "H", tt as "TT", hh as "HH", cc as "CC"
from test_meteo(array[
    row(1,100)::parameter_value,
    row(2,25.0)::parameter_value,
    row(3,765)::parameter_value,
    row(4,15)::parameter_value,
    row(5,6)::parameter_value
], 1);

-- Отрицательное отклонение
select h as "H", tt as "TT", hh as "HH", cc as "CC"
from test_meteo(array[
    row(1,100)::parameter_value,
    row(2,3.0)::parameter_value,
    row(3,750)::parameter_value,
    row(4,0)::parameter_value,
    row(5,0)::parameter_value
], 1);

-- Снос пуль 85 м
select h as "H", tt as "TT", hh as "HH", cc as "CC"
from test_meteo(array[
    row(1,100)::parameter_value,
    row(2,15.0)::parameter_value,
    row(3,750)::parameter_value,
    row(4,10)::parameter_value,
    row(6,85)::parameter_value
], 2);

-- Снос пуль < 40 м
select h as "H", tt as "TT", hh as "HH", cc as "CC"
from test_meteo(array[
    row(1,100)::parameter_value,
    row(2,15.0)::parameter_value,
    row(3,750)::parameter_value,
    row(4,10)::parameter_value,
    row(6,39)::parameter_value
], 2);

-- Значение вне диапазона
select h as "H", tt as "TT", hh as "HH", cc as "CC"
from test_meteo(array[
    row(1,100)::parameter_value,
    row(2,99.0)::parameter_value,
    row(3,750)::parameter_value,
    row(4,10)::parameter_value,
    row(6,39)::parameter_value
], 2);

-- Неизвестное оборудовние
select h as "H", tt as "TT", hh as "HH", cc as "CC"
from test_meteo(array[
    row(1,100)::parameter_value,
    row(2,15.0)::parameter_value,
    row(3,750)::parameter_value,
    row(4,10)::parameter_value,
    row(6,39)::parameter_value
], 3);