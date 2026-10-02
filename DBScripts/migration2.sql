drop table if exists base_measure_units cascade;
drop table if exists measure_units cascade;
drop table if exists parameter_types cascade;

-- Корректировки структуры пачек и параметров

alter table parameters add column package_id int;
comment on column parameters.package_id is 'id Пачки';

update parameters
set package_id = packages.id
from packages
where parameters.id = packages.parameter_id;

alter table packages drop column parameter_id;

-- Базовые еденицы измерения

create table base_measure_units (
    id int generated always as identity primary key,
    short_name text not null unique,
    name text not null
);

comment on table base_measure_units is 'Базовые единицы измерения';
comment on column base_measure_units.id is 'Id базовой единицы';
comment on column base_measure_units.short_name is 'Наименование базовой единицы';
comment on column base_measure_units.name is 'Краткое обозначение';

insert into base_measure_units (short_name, name) values
('м', 'Метр'),
('°C', 'Градус Цельсия'),
('Па', 'Паскаль'),
('°', 'Градус (угол)'),
('м/с', 'Метр в секунду');

select * from base_measure_units;

-- Единицы измерения

create table measure_units (
    id int generated always as identity primary key,
    base_unit_id int not null,
    name text unique not null,
    short_name text not null,
    coefficient numeric not null default 1  -- множитель перевода в базовую единицу
);

comment on table measure_units is 'Единицы измерения';
comment on column measure_units.id is 'Id единицы измерения';
comment on column measure_units.base_unit_id is 'Id базовой единицы измерения';
comment on column measure_units.name is 'Наименование единицы измерения';
comment on column measure_units.short_name is 'Краткое обозначение';
comment on column measure_units.coefficient is 'Коэффициент перевода в базовую единицу';

insert into measure_units (base_unit_id, name, short_name, coefficient)
values
    (1, 'Метр', 'м', 1),
    (1, 'Километр', 'км', 1000),
    (2, 'Градус Цельсия', '°C', 1),
    (3, 'Миллиметр ртутного столба', 'мм рт. ст.', 133.322),
    (3, 'Гектопаскаль', 'гПа', 100),
    (4, 'Градус', '°', 1),
    (4, 'Деление угломера', 'д.у.', 0.06),
    (5, 'Метр в секунду', 'м/с', 1),
    (5, 'Километр в час', 'км/ч', 0.27778);
	
select * from measure_units;

-- Типы параметров

create table parameter_types (
    id int generated always as identity primary key,
    code text not null,
    name text not null,
    unit_id int not null
);

comment on table parameter_types is 'Типы параметров';
comment on column parameter_types.id is 'Id типа параметра';
comment on column parameter_types.code is 'Код параметра';
comment on column parameter_types.name is 'Наименование параметра';
comment on column parameter_types.unit_id is 'Id единицы измерения';

insert into parameter_types (code, name, unit_id)
values
    ('weather_station_height', 'Высота метеостанции', 1),
    ('temperature', 'Температура', 3),
    ('pressure', 'Давление', 4),
    ('wind_direction', 'Направление ветра', 7),
    ('wind_speed', 'Скорость ветра', 9),
    ('bullet_drift', 'Снос пуль', 1);

select * from parameter_types;

-- Новые колонки в таблице parameters

alter table parameters add column value decimal;
alter table parameters add column parameter_type_id int;

comment on column parameters.parameter_type_id is 'Id типа параметра';
comment on column parameters.value is 'Значение параметра';

select * from parameters;

-- Перенос старых значений из колонок в строки

-- Высота метеостанции
insert into parameters (package_id, parameter_type_id, value)
select package_id, 1, weather_station_height
from parameters
where parameter_type_id is null;

-- Температура
insert into parameters (package_id, parameter_type_id, value)
select package_id, 2, temperature
from parameters
where parameter_type_id is null;

-- Давление
insert into parameters (package_id, parameter_type_id, value)
select package_id, 3, pressure
from parameters
where parameter_type_id is null;

-- Направление ветра
insert into parameters (package_id, parameter_type_id, value)
select package_id, 4, wind_direction
from parameters
where parameter_type_id is null;

-- Скорость ветра
insert into parameters (package_id, parameter_type_id, value)
select package_id, 5, wind_speed
from parameters
where parameter_type_id is null;

-- Снос пуль
insert into parameters (package_id, parameter_type_id, value)
select package_id, 6, bullet_drift
from parameters
where parameter_type_id is null;

-- Удаление строк с пустым parameter_type_id

delete from parameters
where parameter_type_id is null;

-- Удаление старых колонок

alter table parameters
    drop column weather_station_height,
    drop column temperature,
    drop column pressure,
    drop column wind_direction,
    drop column wind_speed,
    drop column bullet_drift;

comment on table parameters is 'Таблица значений параметров измерений';

-- Итоговый запрос

select
    pk.date as "Дата измерения",
    pk.id as "Номер пачки",
    u.full_name as "ФИО сотрудника",
    pt.name as "Параметр",
    p.value as "Значение",
    mu.short_name as "Ед. измерения"
from packages pk
join users u on u.id  = pk.user_id
join parameters p on p.package_id = pk.id
join parameter_types pt on pt.id = p.parameter_type_id
join measure_units mu on mu.id = pt.unit_id
order by pk.id, pt.id;