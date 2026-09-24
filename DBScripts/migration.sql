drop table if exists packages cascade;
drop table if exists users cascade;
drop table if exists equipment_type cascade;
drop table if exists parameters cascade;
drop table if exists ranks cascade;

-- Типы оборудования

create table equipment_type(
	id int generated always as identity primary key,
	equipment_name text
);

comment on table equipment_type is 'Таблица видов снаряжения';
comment on column equipment_type.id is 'Id снаряжения';
comment on column equipment_type.equipment_name is 'Имя снаряжения';

insert into equipment_type (equipment_name) 
values ('ДМК'), ('ВР');

-- Пользователи

create table users(
    id int generated always as identity primary key,
	full_name text not null
);

comment on table users is 'Таблица пользователей';
comment on column users.id is 'Id пользователя';
comment on column users.full_name is 'Полное имя пользователя';

insert into users (full_name)
values ('Михаил Вареников Никитич'), ('Максим Болотов Владимирович'),
('Владимир Громов Андреевич'), ('Алексей Королев Дмитриевич');

-- Должности

create table ranks(
	id int generated always as identity primary key,
	rank_name text
);

comment on table ranks is 'Таблица рангов/должностей';
comment on column ranks.id is 'Id должности';
comment on column ranks.rank_name is 'Название должности';

insert into ranks (rank_name) values ('младший Лейтенант'), ('Рядовой'), ('Генерал'), ('Майор');

-- Параметры

create table parameters (
    id int generated always as identity primary key,
	weather_station_height int default 100,
	temperature float default 15,
    pressure int default 750,
	wind_direction int default 0,
	wind_speed int default 0,
	bullet_drift int default 0
);

comment on table parameters is 'Таблица параметров';
comment on column parameters.id is 'Id измерения параметров';
comment on column parameters.weather_station_height is 'Высота метеостанции';
comment on column parameters.temperature is 'Температура';
comment on column parameters.pressure is 'Давление';
comment on column parameters.wind_direction is 'Направление ветра';
comment on column parameters.wind_speed is 'Скорость ветра';
comment on column parameters.bullet_drift is 'Дальность сноса пуль';

insert into parameters (weather_station_height, pressure, wind_speed)
values (1233, 747, 12), (133, 767, 18), (1453, 720, 33), (443, 757, 22);

-- Пачки

create table packages (
    id int generated always as identity primary key,
	user_id int,
	parameter_id int,
	equipment_id int,
	date timestamp default CURRENT_TIMESTAMP
);

insert into packages(user_id, parameter_id, equipment_id) values
(1, 1, 1), (2, 2, 1), (3, 3, 1), (4, 4, 1);

comment on table packages is 'Таблица пакетов(логов) измерений';
comment on column packages.id is 'Id пакета измерений';
comment on column packages.user_id is 'Id пользователя выполнившего измерения';
comment on column packages.equipment_id is 'Id использованного оборудования';
comment on column packages.date is 'Дата и время измерений';

-- Вывод объеденённой таблицы

select
    p.id as package_id,
    p.date as measurement_date,
    u.full_name,
    e.equipment_name,
    par.weather_station_height,
    par.temperature,
    par.pressure,
    par.wind_direction,
    par.wind_speed,
    par.bullet_drift
from packages p
join users u on u.id = p.user_id
join parameters par on par.id = p.parameter_id
join equipment_type e on e.id = p.equipment_id
order by p.id;