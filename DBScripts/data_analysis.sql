-- 1. Одинаковое ли количество измерений у каждого пользователя

-- Количество пачек и значений по каждому пользователю

select
    u.id as "Id пользователя",
    u.full_name as "ФИО сотрудника",
    count(distinct pk.id) as "Количество пачек",
    count(p.id) as "Количество значений",
    min(pk.date) as "Первое измерение",
    max(pk.date) as "Последнее измерение"
from users u
left join packages pk on pk.user_id = u.id
left join parameters p on p.packadge_id = pk.id
group by u.id, u.full_name
order by count(distinct pk.id) desc, u.id;


-- 2. Есть ли пустые пачки

-- Пустые пачки

select
    pk.id as "Номер пачки",
    pk.date as "Дата измерения",
    u.full_name as "ФИО сотрудника",
    e.equipment_name as "Оборудование",
    count(p.id) as "Строк в parameters",
    count(p.value) as "Заполненных значений"
from packages pk
left join parameters p on p.package_id = pk.id
left join users u on u.id = pk.user_id
left join equipment_type e on e.id = pk.equipment_id
group by pk.id, pk.date, u.full_name, e.equipment_name
having count(p.value) = 0
order by pk.id;



-- 3. Полнота пачек: в каждой пачке должно быть 5 параметров (какие именно - зависит от оборудования)

-- Сколько значений в пачке

select
    t.values_count as "Значений в пачке",
    count(*) as "Количество пачек"
from (
    select pk.id, count(p.id) as values_count
    from packages pk
    left join parameters p on p.package_id = pk.id
    group by pk.id
) t
group by t.values_count
order by t.values_count;


-- 4. Корректность значений: диапазон, заполненность, формат (знаки после запятой)

select
    pk.id as "Номер пачки",
    pk.date as "Дата измерения",
    u.full_name as "ФИО сотрудника",
    e.equipment_name as "Оборудование",
    pt.name as "Параметр",
    p.value as "Значение",
    mu.short_name as "Ед. измерения",
    r.min_value as "Минимум по ТЗ",
    r.max_value as "Максимум по ТЗ"
from parameters p
left join packages pk on pk.id = p.package_id
left join users u on u.id = pk.user_id
left join equipment_type e on e.id = pk.equipment_id
left join parameter_types pt on pt.id = p.parameter_type_id
left join measure_units mu on mu.id = pt.unit_id
left join (
    values
        ('weather_station_height', -100, 2000, 0),  -- высота
        ('temperature', -58, 58, 1),    -- температура
        ('pressure', 500, 900, 0),  -- давление
        ('wind_direction', 0, 59, 0),   -- направление ветра
        ('wind_speed', 0, 15, 0),   -- скорость ветра (ДМК)
        ('bullet_drift', 0, 150, 0) -- снос пуль (ВР)
) as r(code, min_value, max_value, decimals) on r.code = pt.code
where p.value is null
   or r.code is null
   or p.value < r.min_value
   or p.value > r.max_value
   or p.value <> round(p.value, r.decimals) -- Проверка на количество знаков после запятой
order by pk.id, pt.id;
 
-- 5. Единицы измерения: подходят ли они своим параметрам
 
select
    pt.id as "Id параметра",
    pt.name as "Параметр",
    mu.short_name as "Единица в БД",
    r.unit_short_name as "Единица по ТЗ",
    bu.short_name as "Базовая единица в БД",
    r.base_unit_short_name as "Базовая единица по ТЗ",
    mu.coefficient as "Коэффициент"
from parameter_types pt
left join measure_units mu on mu.id = pt.unit_id
left join base_measure_units bu on bu.id = mu.base_unit_id
left join (
    values
        ('weather_station_height', 'м', 'м'),       -- высота
        ('temperature', '°C', '°C'),                -- температура
        ('pressure', 'мм рт. ст.', 'Па'),           -- давление
        ('wind_direction', 'д.у.', '°'),            -- направление ветра
        ('wind_speed', 'м/с', 'м/с'),               -- скорость ветра
        ('bullet_drift', 'м', 'м')         -- снос пуль
) as r(code, unit_short_name, base_unit_short_name) on r.code = pt.code
order by pt.id;

-- Обновление некорректного к тз параметра

update parameter_types
set unit_id = (select id from measure_units where name = 'Метр в секунду')
where code = 'wind_speed';