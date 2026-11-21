-- Таблицы и справочники для корректировок по высоте

do $$
begin

    drop table if exists calc_correction cascade;
    drop table if exists calc_correction_types cascade;
    drop table if exists calc_correction_headers cascade;
    drop table if exists calc_correction_heights cascade;

    drop sequence if exists calc_correction_seq cascade;
    drop sequence if exists calc_correction_types_seq cascade;
    drop sequence if exists calc_correction_headers_seq cascade;
    drop sequence if exists calc_correction_height_seq cascade;

    -- Счетчики

    create sequence calc_correction_height_seq;
    create sequence calc_correction_headers_seq;
    create sequence calc_correction_types_seq;
    create sequence calc_correction_seq;

    -- Таблица стандартных высот

    create table calc_correction_heights (
        id int primary key not null default nextval('calc_correction_height_seq'),
        height int not null unique
    );

    alter sequence calc_correction_height_seq owned by calc_correction_heights.id;

    comment on table calc_correction_heights is 'Таблица стандартных высот';
    comment on column calc_correction_heights.id is 'Уникальный код';
    comment on column calc_correction_heights.height is 'Высота';

    -- Справочник заголовков таблиц корректировок

    create table calc_correction_headers (
        id int primary key not null default nextval('calc_correction_headers_seq'),
        description text not null,
        header_values int[] not null
    );

    alter sequence calc_correction_headers_seq owned by calc_correction_headers.id;

    comment on table calc_correction_headers is 'Справочник заголовков таблиц корректировок';
    comment on column calc_correction_headers.id is 'Уникальный код';
    comment on column calc_correction_headers.description is 'Описание';
    comment on column calc_correction_headers.header_values is 'Значения заголовка таблицы';

    -- Справочник типов таблиц корректировок

    create table calc_correction_types (
        id int primary key not null default nextval('calc_correction_types_seq'),
        parent_id int,
        measurment_equipment_id int,
        header_id int,
        description text not null
    );

    alter sequence calc_correction_types_seq owned by calc_correction_types.id;

    comment on table calc_correction_types is 'Справочник типов таблиц корректировок';
    comment on column calc_correction_types.id is 'Уникальный код';
    comment on column calc_correction_types.parent_id is 'Уникальный код владельца - тип таблицы';
    comment on column calc_correction_types.measurment_equipment_id is 'Тип оборудования';
    comment on column calc_correction_types.header_id is 'Код заголовка';
    comment on column calc_correction_types.description is 'Описание к таблице';

    -- Универсальная таблица корректировок

    create table calc_correction (
        id int primary key not null default nextval('calc_correction_seq'),
        height_id int not null,
        type_id int not null,
        row_values int[] not null
    );

    alter sequence calc_correction_seq owned by calc_correction.id;

    comment on table calc_correction is 'Универсальная таблица корректировок';
    comment on column calc_correction.id is 'Уникальный код';
    comment on column calc_correction.height_id is 'Код высоты';
    comment on column calc_correction.type_id is 'Код типа таблиц';
    comment on column calc_correction.row_values is 'Значения с корректировками';

    -- Стандартные высоты

    insert into calc_correction_heights (height) values
        (200), (400), (800), (1200), (1600), (2000), (2400), (3000), (4000);

    -- Заголовки таблиц корректировок

    insert into calc_correction_headers (description, header_values) values
        ('Отклонения приземной виртуальной температуры (Таблица 2)',
         array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]), -- 1
        ('Дальность сноса ветровых пуль ВР (Таблица 3)',
         array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]), -- 2
        ('Скорость приземного ветра ДМК (Таблица 3)',
         array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]); -- 3

    -- Типы таблиц корректировок

    insert into calc_correction_types (description, parent_id, measurment_equipment_id, header_id) values
        ('Таблица 2', null, null, null), -- 1
        ('Таблица 3, скорость среднего ветра', null, null, null), -- 2
        ('Таблица 3, направление среднего ветра', null, null, null), -- 3
        ('Таблица 3, Скорость среднего ветра (ВР)', 2, 2, 2), -- 4
        ('Таблица 3, Направление среднего ветра (ВР)', 3, 2, null), -- 5
        ('Таблица 3, Скорость среднего ветра (ДМК)', 2, 1, 3), -- 6
        ('Таблица 3, Направление среднего ветра (ДМК)', 3, 1, null), -- 7
        ('Таблица 2, Положительные температуры', 1, null, 1), -- 8
        ('Таблица 2, Отрицательные температуры', 1, null, 1); -- 9

    -- Корректировки

    insert into calc_correction (height_id, type_id, row_values) values
        -- Таблица 2, отрицательные значения (type_id = 9)
        (1, 9, array[-1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49]), -- 200
        (2, 9, array[-1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -38, -48]), -- 400
        (3, 9, array[-1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46]), -- 800
        (4, 9, array[-1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44]), -- 1200
        (5, 9, array[-1, -2, -3, -3, -4, -4, -5, -6, -7, -7, -17, -25, -34, -42]), -- 1600
        (6, 9, array[-1, -2, -3, -3, -4, -4, -5, -6, -6, -7, -16, -24, -32, -40]), -- 2000
        (7, 9, array[-1, -2, -2, -3, -4, -4, -5, -5, -6, -7, -15, -23, -31, -38]), -- 2400
        (8, 9, array[-1, -2, -2, -3, -4, -4, -4, -5, -5, -6, -15, -22, -30, -37]), -- 3000
        (9, 9, array[-1, -2, -2, -3, -4, -4, -4, -4, -5, -6, -14, -20, -27, -34]), -- 4000
        -- Таблица 2, положительные значения (type_id = 8), для 40 и 50 в таблице прочерки
        (1, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, null, null]), -- 200
        (2, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, null, null]), -- 400
        (3, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, null, null]), -- 800
        (4, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, null, null]), -- 1200
        (5, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, null, null]), -- 1600
        (6, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, null, null]), -- 2000
        (7, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, null, null]), -- 2400
        (8, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, null, null]), -- 3000
        (9, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, null, null]), -- 4000
        -- Таблица 3, скорость среднего ветра ВР (type_id = 4)
        (1, 4, array[3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 12]), -- 200
        (2, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]), -- 400
        (3, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16]), -- 800
        (4, 4, array[4, 5, 7, 8, 8, 9, 11, 12, 13, 15, 15, 16]), -- 1200
        (5, 4, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 15, 17, 17]), -- 1600
        (6, 4, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 16, 17, 18]), -- 2000
        (7, 4, array[4, 6, 8, 9, 9, 10, 12, 14, 15, 16, 18, 19]), -- 2400
        (8, 4, array[5, 6, 8, 9, 10, 11, 12, 14, 15, 17, 18, 19]), -- 3000
        (9, 4, array[5, 6, 8, 9, 10, 11, 12, 14, 16, 18, 19, 20]), -- 4000
        -- Таблица 3, направление среднего ветра ВР (type_id = 5)
        (1, 5, array[0]), -- 200
        (2, 5, array[1]), -- 400
        (3, 5, array[2]), -- 800
        (4, 5, array[2]), -- 1200
        (5, 5, array[3]), -- 1600
        (6, 5, array[3]), -- 2000
        (7, 5, array[3]), -- 2400
        (8, 5, array[4]), -- 3000
        (9, 5, array[4]), -- 4000
        -- Таблица 3, скорость среднего ветра ДМК (type_id = 6)
        (1, 6, array[4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22]), -- 200
        (2, 6, array[5, 7, 10, 11, 12, 14, 17, 18, 20, 22, 23, 25, 27]), -- 400
        (3, 6, array[5, 8, 10, 11, 13, 15, 18, 19, 21, 23, 25, 27, 28]), -- 800
        (4, 6, array[5, 8, 11, 12, 13, 16, 19, 20, 22, 24, 26, 28, 30]), -- 1200
        (5, 6, array[6, 8, 11, 13, 14, 17, 20, 21, 23, 25, 27, 29, 32]), -- 1600
        (6, 6, array[6, 9, 11, 13, 14, 17, 20, 21, 24, 26, 28, 30, 32]), -- 2000
        (7, 6, array[6, 9, 12, 14, 15, 18, 21, 22, 25, 27, 29, 32, 34]), -- 2400
        (8, 6, array[6, 9, 12, 14, 15, 18, 21, 23, 25, 28, 30, 32, 36]), -- 3000
        (9, 6, array[6, 10, 12, 14, 16, 19, 22, 24, 26, 29, 32, 34, 36]), -- 4000
        -- Таблица 3, направление среднего ветра ДМК (type_id = 7)
        (1, 7, array[1]), -- 200
        (2, 7, array[2]), -- 400
        (3, 7, array[3]), -- 800
        (4, 7, array[3]), -- 1200
        (5, 7, array[4]), -- 1600
        (6, 7, array[4]), -- 2000
        (7, 7, array[4]), -- 2400
        (8, 7, array[5]), -- 3000
        (9, 7, array[5]); -- 4000

    -- Связи

    alter table calc_correction_types
        add foreign key (parent_id) references calc_correction_types(id) on delete cascade,
        add foreign key (measurment_equipment_id) references equipment_type(id) on delete cascade,
        add foreign key (header_id) references calc_correction_headers(id) on delete set null;

    alter table calc_correction
        add foreign key (height_id) references calc_correction_heights(id) on delete cascade,
        add foreign key (type_id) references calc_correction_types(id) on delete cascade,
        add unique (height_id, type_id);

    commit;

end;
$$;
