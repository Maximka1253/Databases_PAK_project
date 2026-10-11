-- Генерация структуры таблиц (транзакция 1)

do $$
begin
    -- Структура таблиц и справочники

    drop table if exists parameters cascade;
    drop table if exists packages cascade;
    drop table if exists parameter_types cascade;
    drop table if exists measure_units cascade;
    drop table if exists users cascade;
    drop table if exists base_measure_units cascade;
    drop table if exists ranks cascade;
    drop table if exists equipment_type cascade;
    drop table if exists temperature_correction cascade;

    -- Типы оборудования

    create table equipment_type (
        id int generated always as identity primary key, -- Счетчик
        equipment_name text
    );

    comment on table equipment_type is 'Таблица видов снаряжения';
    comment on column equipment_type.id is 'Id снаряжения';
    comment on column equipment_type.equipment_name is 'Имя снаряжения';

    -- Пользователи

    create table users (
        id int generated always as identity primary key,
        full_name text not null, 
        rank_id int
    );

    comment on table users is 'Таблица пользователей';
    comment on column users.id is 'Id пользователя';
    comment on column users.full_name is 'Полное имя пользователя';

    -- Должности

    create table ranks (
        id int generated always as identity primary key,
        rank_name text
    );

    comment on table ranks is 'Таблица рангов/должностей';
    comment on column ranks.id is 'Id должности';
    comment on column ranks.rank_name is 'Название должности';

    -- Базовые единицы измерения

    create table base_measure_units (
        id int generated always as identity primary key,
        short_name text not null unique,
        name text not null
    );

    comment on table base_measure_units is 'Базовые единицы измерения';
    comment on column base_measure_units.id is 'Id базовой единицы';
    comment on column base_measure_units.short_name is 'Краткое обозначение';
    comment on column base_measure_units.name is 'Наименование базовой единицы';


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

    -- Пачки

    create table packages (
        id int generated always as identity primary key,
        user_id int,
        equipment_id int,
        date timestamp default CURRENT_TIMESTAMP
    );

    comment on table packages is 'Таблица пакетов(логов) измерений';
    comment on column packages.id is 'Id пакета измерений';
    comment on column packages.user_id is 'Id пользователя выполнившего измерения';
    comment on column packages.equipment_id is 'Id использованного оборудования';
    comment on column packages.date is 'Дата и время измерений';

    -- Параметры

    create table parameters (
        id int generated always as identity primary key,
        package_id int,
        parameter_type_id int,
        value decimal
    );

    comment on table parameters is 'Таблица значений параметров измерений';
    comment on column parameters.id is 'Id измерения параметров';
    comment on column parameters.package_id is 'Id пачки';
    comment on column parameters.parameter_type_id is 'Id типа параметра';
    comment on column parameters.value is 'Значение параметра';

    -- Коррекция температур

    create table temperature_correction (
        id int generated always as identity primary key,
        t0 decimal(4, 1),
        delta_tv decimal(4, 1)
    );
 
    comment on table temperature_correction is 'Таблица виртуальных поправок температуры (таблица 1 ТЗ)';
    comment on column temperature_correction.id is 'Id опорной точки';
    comment on column temperature_correction.t0 is 'Измеренная приземная температура воздуха, °C';
    comment on column temperature_correction.delta_tv is 'Виртуальная поправка, °C';
end;
$$;

-- Связи и ограничения (транзакция 2)

do $$
begin
    -- Связи

    alter table measure_units
        add foreign key (base_unit_id) references base_measure_units(id);

    alter table users
        add foreign key (rank_id) references ranks(id),
        alter column rank_id set not null;

    alter table parameter_types
        add foreign key (unit_id) references measure_units(id);

    alter table packages
        add foreign key (user_id) references users(id),
        add foreign key (equipment_id) references equipment_type(id);

    alter table parameters
        add foreign key (package_id) references packages(id) on delete cascade,
        add foreign key (parameter_type_id) references parameter_types(id);

	-- Обязательные поля

	alter table equipment_type alter column equipment_name set not null;
    alter table ranks alter column rank_name set not null;
	alter table packages alter column date set not null;
	alter table parameters alter column value set not null;

	-- Уникальность

	alter table equipment_type add unique (equipment_name);
    alter table ranks add unique (rank_name);
	alter table parameter_types add unique (code);
	alter table parameters add unique (package_id, parameter_type_id);
	alter table temperature_correction add unique (t0);

	-- Ограничения значений параметров по тз

	alter table parameters
		add check (parameter_type_id <> 1 or value = trunc(value)),
		add check (parameter_type_id <> 2 or (value between -58 and 58 and value = round(value, 1))),
		add check (parameter_type_id <> 3 or (value between 500 and 900 and value = trunc(value))),
		add check (parameter_type_id <> 4 or (value between 0 and 59 and value = trunc(value))),
		add check (parameter_type_id <> 5 or (value between 0 and 15 and value = trunc(value))),
		add check (parameter_type_id <> 6 or (value between 0 and 150 and value = trunc(value)));
end;
$$;