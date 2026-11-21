do $$
begin
    drop table if exists wind_speed_correction cascade;
    drop table if exists wind_angle_increment cascade;
    drop table if exists temperature_avg_deviation cascade;
    drop table if exists standard_heights cascade;

    -- Счетчики

    create sequence standard_heights_id_seq;
    create sequence temperature_avg_deviation_id_seq;
    create sequence wind_angle_increment_id_seq;
    create sequence wind_speed_correction_id_seq;

    -- Справочник стандартных высот

    create table standard_heights (
        id int primary key default nextval('standard_heights_id_seq'),
        height int
    );

    alter sequence standard_heights_id_seq owned by standard_heights.id;

    -- Таблица 2: Средние отклонения температуры воздуха (общая для ДМК и ВР)

    create table temperature_avg_deviation (
        id int primary key default nextval('temperature_avg_deviation_id_seq'),
        height_id int,
        delta_t0 int,
        negative_deviation int,
        positive_deviation int
    );

    alter sequence temperature_avg_deviation_id_seq owned by temperature_avg_deviation.id;

    -- Таблица 3 (углы): Приращение дирекционного угла направления ветра (ДМК и ВР)

    create table wind_angle_increment (
        id int primary key default nextval('wind_angle_increment_id_seq'),
        equipment_id int,
        height_id int,
        angle_increment int
    );

    alter sequence wind_angle_increment_id_seq owned by wind_angle_increment.id;

    -- Таблица 3: Скорость среднего ветра (объединенная для ДМК и ВР)

    create table wind_speed_correction (
        id int primary key default nextval('wind_speed_correction_id_seq'),
        equipment_id int,
        height_id int,
        input_value numeric,
        avg_wind_speed numeric
    );

    alter sequence wind_speed_correction_id_seq owned by wind_speed_correction.id;

    -- Связи

    alter table temperature_avg_deviation
        add foreign key (height_id) references standard_heights(id);

    alter table wind_angle_increment
        add foreign key (equipment_id) references equipment_type(id),
        add foreign key (height_id) references standard_heights(id);

    alter table wind_speed_correction
        add foreign key (equipment_id) references equipment_type(id),
        add foreign key (height_id) references standard_heights(id);
end $$