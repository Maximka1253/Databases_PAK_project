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

    -- Счетчики

    create sequence equipment_type_id_seq;
    create sequence users_id_seq;
    create sequence ranks_id_seq;
    create sequence base_measure_units_id_seq;
    create sequence measure_units_id_seq;
    create sequence parameter_types_id_seq;
    create sequence packages_id_seq;
    create sequence parameters_id_seq;
    create sequence temperature_correction_id_seq;

    -- Типы оборудования

    create table equipment_type (
        id int primary key default nextval('equipment_type_id_seq'),
        equipment_name text
    );

    alter sequence equipment_type_id_seq owned by equipment_type.id;

    comment on table equipment_type is 'Таблица видов снаряжения';
    comment on column equipment_type.id is 'Id снаряжения';
    comment on column equipment_type.equipment_name is 'Имя снаряжения';

    -- Пользователи

    create table users (
        id int primary key default nextval('users_id_seq'),
        full_name text not null, 
        rank_id int
    );

    alter sequence users_id_seq owned by users.id;

    comment on table users is 'Таблица пользователей';
    comment on column users.id is 'Id пользователя';
    comment on column users.full_name is 'Полное имя пользователя';

    -- Должности

    create table ranks (
        id int primary key default nextval('ranks_id_seq'),
        rank_name text
    );

    alter sequence ranks_id_seq owned by ranks.id;

    comment on table ranks is 'Таблица рангов/должностей';
    comment on column ranks.id is 'Id должности';
    comment on column ranks.rank_name is 'Название должности';

    -- Базовые единицы измерения

    create table base_measure_units (
        id int primary key default nextval('base_measure_units_id_seq'),
        short_name text not null unique,
        name text not null
    );

    alter sequence base_measure_units_id_seq owned by base_measure_units.id;

    comment on table base_measure_units is 'Базовые единицы измерения';
    comment on column base_measure_units.id is 'Id базовой единицы';
    comment on column base_measure_units.short_name is 'Краткое обозначение';
    comment on column base_measure_units.name is 'Наименование базовой единицы';


    -- Единицы измерения

    create table measure_units (
        id int primary key default nextval('measure_units_id_seq'),
        base_unit_id int not null,
        name text unique not null,
        short_name text not null,
        coefficient numeric not null default 1  -- множитель перевода в базовую единицу
    );

    alter sequence measure_units_id_seq owned by measure_units.id;

    comment on table measure_units is 'Единицы измерения';
    comment on column measure_units.id is 'Id единицы измерения';
    comment on column measure_units.base_unit_id is 'Id базовой единицы измерения';
    comment on column measure_units.name is 'Наименование единицы измерения';
    comment on column measure_units.short_name is 'Краткое обозначение';
    comment on column measure_units.coefficient is 'Коэффициент перевода в базовую единицу';

    -- Типы параметров

    create table parameter_types (
        id int primary key default nextval('parameter_types_id_seq'),
        code text not null,
        name text not null,
        unit_id int not null
    );

    alter sequence parameter_types_id_seq owned by parameter_types.id;

    comment on table parameter_types is 'Типы параметров';
    comment on column parameter_types.id is 'Id типа параметра';
    comment on column parameter_types.code is 'Код параметра';
    comment on column parameter_types.name is 'Наименование параметра';
    comment on column parameter_types.unit_id is 'Id единицы измерения';

    -- Пачки

    create table packages (
        id int primary key default nextval('packages_id_seq'),
        user_id int,
        equipment_id int,
        date timestamp default CURRENT_TIMESTAMP
    );

    alter sequence packages_id_seq owned by packages.id;

    comment on table packages is 'Таблица пакетов(логов) измерений';
    comment on column packages.id is 'Id пакета измерений';
    comment on column packages.user_id is 'Id пользователя выполнившего измерения';
    comment on column packages.equipment_id is 'Id использованного оборудования';
    comment on column packages.date is 'Дата и время измерений';

    -- Параметры

    create table parameters (
        id int primary key default nextval('parameters_id_seq'),
        package_id int,
        parameter_type_id int,
        value decimal
    );

    alter sequence parameters_id_seq owned by parameters.id;

    comment on table parameters is 'Таблица значений параметров измерений';
    comment on column parameters.id is 'Id измерения параметров';
    comment on column parameters.package_id is 'Id пачки';
    comment on column parameters.parameter_type_id is 'Id типа параметра';
    comment on column parameters.value is 'Значение параметра';

    -- Коррекция температур

    create table temperature_correction (
        id int primary key default nextval('temperature_correction_id_seq'),
        t0 decimal(4, 1),
        delta_tv decimal(4, 1)
    );

    alter sequence temperature_correction_id_seq owned by temperature_correction.id;
 
    comment on table temperature_correction is 'Таблица виртуальных поправок температуры (таблица 1 ТЗ)';
    comment on column temperature_correction.id is 'Id опорной точки';
    comment on column temperature_correction.t0 is 'Измеренная приземная температура воздуха, °C';
    comment on column temperature_correction.delta_tv is 'Виртуальная поправка, °C';

    commit;

	begin
    -- Вставка справочников

    -- Типы оборудования
        
    insert into equipment_type (equipment_name) values
        ('ДМК'),
        ('ВР');

    -- Единицы измерения

    insert into base_measure_units (short_name, name) values
        ('м', 'Метр'),
        ('°C', 'Градус Цельсия'),
        ('Па', 'Паскаль'),
        ('°', 'Градус (угол)'),
        ('м/с', 'Метр в секунду');

    -- Вставка должностей

    insert into ranks (rank_name) values 
        ('младший Лейтенант'),
        ('Рядовой'),
        ('Генерал'),
        ('Майор'),
		('Сержант');

    -- Еденицы измерения

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
        (5, 'Километр в час', 'км/ч', 0.27778),
        (4, 'Большое деление угломера', 'б.д.у.', 6);  -- 1 большое деление = 6 градусов (60 делений = 360)

    -- Типы параметров

    insert into parameter_types (code, name, unit_id) values
        ('weather_station_height', 'Высота метеостанции', 1),
        ('temperature', 'Температура', 3),
        ('pressure', 'Давление', 4),
        ('wind_direction', 'Направление ветра', 10),
        ('wind_speed', 'Скорость ветра', 8),
        ('bullet_drift', 'Снос пуль', 1);


    -- Таблица вычисления температуры

    insert into temperature_correction (t0, delta_tv) values
        (-1.0, 0.0),
        (0.0, 0.5),
        (5.0, 0.5),
        (10.0, 1.0),
        (15.0, 1.0),
        (20.0, 1.5),
        (25.0, 2.0),
        (30.0, 3.5),
        (40.0, 4.5);

    commit;

	begin
    -- Тестовые данные

    insert into users (full_name, rank_id) values
        ('Михаил Вареников Никитич', 4),
        ('Максим Болотов Владимирович', 2),
        ('Владимир Громов Андреевич', 1),
        ('Алексей Королев Дмитриевич', 4),
        ('Сергей Петров Иванович', 2),
        ('Дмитрий Соколов Олегович', 5),
        ('Игорь Смирнов Александрович', 3),
        ('Павел Кузнецов Сергеевич', 2),
        ('Андрей Попов Викторович', 1),
        ('Николай Лебедев Дмитриевич', 5),
        ('Олег Морозов Павлович', 4),
        ('Денис Новиков Андреевич', 3),
        ('Тимур Ахметов Ренатович', 5),
        ('Виктор Захаров Николаевич', 1),
        ('Артём Фёдоров Ильич', 1),
        ('Евгений Тарасов Геннадьевич', 2),
        ('Роман Григорьев Олегович', 3);

    -- Пачки измерений и значения параметров

    with measurements (full_name, equipment_name, date, height, temperature, pressure, wind_direction, wind_value) as (
        values
        ('Михаил Вареников Никитич',      'ДМК', timestamp '2026-01-15 08:30:00', 110, 12.5, 755, 15, 6),
        ('Максим Болотов Владимирович',   'ДМК', timestamp '2026-01-15 09:10:00', 95, -3.2, 742, 30, 4),
        ('Владимир Громов Андреевич',     'ВР',  timestamp '2026-01-16 10:15:00', 130, 22.0, 758, 10, 85),
        ('Алексей Королев Дмитриевич',    'ДМК', timestamp '2026-02-02 07:45:00', 100, 15.0, 750, 0, 0),
        ('Сергей Петров Иванович',        'ВР',  timestamp '2026-02-03 11:20:00', 250, 5.5, 735, 45, 120),
        ('Дмитрий Соколов Олегович',      'ДМК', timestamp '2026-02-10 06:30:00', 80, -12.4, 770, 22, 9),
        ('Игорь Смирнов Александрович',   'ВР',  timestamp '2026-03-01 12:00:00', 300, 28.3, 760, 5, 40),
        ('Павел Кузнецов Сергеевич',      'ДМК', timestamp '2026-03-05 08:10:00', 150, 18.7, 748, 33, 7),
        ('Андрей Попов Викторович',       'ВР',  timestamp '2026-03-12 09:40:00', 175, -5.0, 752, 27, 95),
        ('Николай Лебедев Дмитриевич',    'ДМК', timestamp '2026-04-01 07:00:00', 100, 25.0, 765, 15, 6),
        ('Олег Морозов Павлович',         'ВР',  timestamp '2026-04-07 14:25:00', 200, 10.2, 743, 50, 110),
        ('Денис Новиков Андреевич',       'ДМК', timestamp '2026-05-11 10:00:00', 90, 7.8, 751, 12, 3),
        ('Тимур Ахметов Ренатович',       'ВР',  timestamp '2026-05-20 16:30:00', 140, -15.6, 738, 38, 65),
        ('Виктор Захаров Николаевич',     'ВР',  timestamp '2026-06-01 09:00:00', 105, 16.4, 749, 20, 70),
        ('Артём Фёдоров Ильич',           'ДМК', timestamp '2026-06-15 11:00:00', 100, 17.5, 760, 8, 11),
        ('Евгений Тарасов Геннадьевич',   'ДМК', timestamp '2026-07-01 08:00:00', 120, 14.0, 755, 10, 5),
        ('Роман Григорьев Олегович',      'ВР',  timestamp '2026-07-02 09:30:00', 110, 20.0, 748, 55, 140),
        ('Михаил Вареников Никитич',      'ДМК', timestamp '2026-07-03 10:00:00', 100, -7.0, 750, 15, 2),
        ('Максим Болотов Владимирович',   'ДМК', timestamp '2026-07-04 11:00:00', 85, 11.1, 752, 21, 4),
        ('Владимир Громов Андреевич',     'ДМК', timestamp '2026-07-05 12:00:00', 95, 13.4, 757, 3, 8),
        ('Алексей Королев Дмитриевич',    'ВР',  timestamp '2026-07-09 08:20:00', 120, 21.3, 750, 59, 150),
        ('Сергей Петров Иванович',        'ДМК', timestamp '2026-07-14 09:45:00', 70, 24.8, 756, 0, 15),
        ('Дмитрий Соколов Олегович',      'ВР',  timestamp '2026-07-19 07:30:00', 180, 19.5, 745, 33, 0),
        ('Игорь Смирнов Александрович',   'ВР',  timestamp '2026-07-24 10:10:00', 90, 26.1, 753, 41, 75),
        ('Павел Кузнецов Сергеевич',      'ДМК', timestamp '2026-07-29 13:00:00', 210, 23.0, 739, 28, 7),
        ('Андрей Попов Викторович',       'ВР',  timestamp '2026-08-03 06:50:00', 60, 18.9, 757, 17, 55),
        ('Николай Лебедев Дмитриевич',    'ДМК', timestamp '2026-08-08 11:35:00', 130, 27.4, 751, 46, 10),
        ('Олег Морозов Павлович',         'ВР',  timestamp '2026-08-13 09:15:00', 160, 22.6, 746, 9, 100),
        ('Денис Новиков Андреевич',       'ВР',  timestamp '2026-08-18 14:20:00', 95, 20.2, 754, 52, 30),
        ('Тимур Ахметов Ренатович',       'ДМК', timestamp '2026-08-23 08:05:00', 140, 25.5, 749, 24, 3),
        ('Виктор Захаров Николаевич',     'ВР',  timestamp '2026-08-28 10:40:00', 220, 17.8, 741, 36, 125),
        ('Артём Фёдоров Ильич',           'ДМК', timestamp '2026-09-02 12:25:00', 105, 19.1, 752, 13, 12),
        ('Евгений Тарасов Геннадьевич',   'ВР',  timestamp '2026-09-07 07:15:00', 85, 14.7, 755, 48, 90),
        ('Роман Григорьев Олегович',      'ВР',  timestamp '2026-09-12 09:55:00', 150, 12.3, 747, 6, 60)
    ),
    new_packages as (
    insert into packages (user_id, equipment_id, date)
        select u.id, e.id, m.date
        from measurements m
        join users u on u.full_name = m.full_name
        join equipment_type e on e.equipment_name = m.equipment_name
        order by m.date
        returning id, date, equipment_id
    )
    insert into parameters (package_id, parameter_type_id, value)
        select p.id, t.parameter_type_id, t.value
        from new_packages p
        join measurements m on m.date = p.date
        join equipment_type e on e.id = p.equipment_id
        cross join lateral (
            values
                (1, m.height),
                (2, m.temperature),
                (3, m.pressure),
                (4, m.wind_direction),
                (case e.equipment_name when 'ДМК' then 5 else 6 end, m.wind_value)
        ) as t (parameter_type_id, value)
        order by p.id, t.parameter_type_id;
    commit;

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

    commit;
end;
$$;
