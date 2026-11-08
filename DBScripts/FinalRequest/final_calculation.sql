do $$
begin

    drop procedure if exists calculate_meteo_heights(parameter_value[], int, meteo_height_result[]);
    drop function if exists meteo_delta_t0(numeric);
    drop function if exists meteo_format_h(int);
    drop function if exists meteo_format_tt(int);
    drop function if exists meteo_format_hh(int);
    drop function if exists meteo_format_cc(int);
    drop type if exists meteo_height_result cascade;

    -- Исправление неверных значений в таблице поправок

    update temperature_correction
    set delta_tv = 0.0
    where t0 = 0.0
    and delta_tv = 0.5;

    -- Расширение типа параметров интерполяции
    alter type interpolation_params
        alter attribute x0 type numeric,
        alter attribute y0 type numeric,
        alter attribute x1 type numeric,
        alter attribute y1 type numeric;

    -- Тип расчетных данных высот
    create type meteo_height_result as (
        height int,
        h text,
        delta_t int,
        tt text,
        wind_direction int,
        hh text,
        wind_speed int,
        cc text
    );

    comment on type meteo_height_result is 'Расчетные данные по одной типовой высоте';
    comment on column meteo_height_result.height is 'Типовая высота, м';
    comment on column meteo_height_result.h is 'Высота в формате H (сотни метров)';
    comment on column meteo_height_result.delta_t is 'Среднее отклонение температуры, °C';
    comment on column meteo_height_result.tt is 'Среднее отклонение температуры в формате TT';
    comment on column meteo_height_result.wind_direction is 'Направление среднего ветра, б.д.у.';
    comment on column meteo_height_result.hh is 'Направление среднего ветра в формате HH';
    comment on column meteo_height_result.wind_speed is 'Скорость среднего ветра, м/с';
    comment on column meteo_height_result.cc is 'Скорость среднего ветра в формате CC';

    -- H (высота в сотнях метров)
    create or replace function meteo_format_h(p_height int)
    returns text
    language sql
    as $body$
        select lpad((p_height / 100)::text, 2, '0');
    $body$;

    -- TT (среднее отклонение температуры)
    create or replace function meteo_format_tt(p_delta_t int)
    returns text
    language sql
    as $body$
        select case
            when p_delta_t < 0
                then lpad((get_meteo_constant('negative_temperature_base')::int + abs(p_delta_t))::text, 2, '0')
            else lpad(p_delta_t::text, 2, '0')
        end;
    $body$;

    -- HH (направление среднего ветра)
    create or replace function meteo_format_hh(p_direction int)
    returns text
    language sql
    as $body$
        select lpad((p_direction % 60)::text, 2, '0');
    $body$;

    -- CC (скорость среднего ветра)
    create or replace function meteo_format_cc(p_speed int)
    returns text
    language sql
    as $body$
        select lpad(p_speed::text, 2, '0');
    $body$;

    -- Отклонение приземной виртуальной температуры
    create or replace function meteo_delta_t0(p_temperature numeric)
    returns int
    language sql
    as $body$
        select round(
            p_temperature + calculate_interpolation(
                p_temperature,
                get_interpolation_params(p_temperature)
            ) - get_meteo_constant('table_temperature')
        )::int;
    $body$;

    -- Хранимая процедура расчета Метео-11 по типовым высотам
    -- p_params - входящие параметры
    -- p_equipment_id - тип оборудования
    -- p_results - расчетные данные по каждой типовой высоте
    create or replace procedure calculate_meteo_heights(
        p_params parameter_value[],
        p_equipment_id int,
        inout p_results meteo_height_result[] default '{}'
    )
    language plpgsql
    as $body$
    declare
        v_error text;
        v_temperature numeric;
        v_wind_direction int;
        v_wind_input numeric;
        v_delta_t0 int;
        v_idx_lo int;
        v_idx_hi int;
        v_rec record;
        v_delta_t int;
        v_wind_speed int;
        v_wind_dir int;
    begin
        p_results := '{}';

        -- Проверка входных параметров
        v_error := validate_parameters((p_equipment_id, p_params)::parameter_list);
        if v_error is not null then
            raise exception 'Ошибка валидации параметров: %', v_error;
        end if;

        -- Значения параметров
        select
            max(p.value) filter (where p.parameter_type_id = 2),
            (max(p.value) filter (where p.parameter_type_id = 4))::int,
            coalesce(
                max(p.value) filter (where p.parameter_type_id = 5),
                max(p.value) filter (where p.parameter_type_id = 6)
            )
        into v_temperature, v_wind_direction, v_wind_input
        from unnest(p_params) p;

        v_delta_t0 := meteo_delta_t0(v_temperature);

        -- Для каждой типовой высоты - строки корретировок и заголовки шкал
		
        for v_rec in
            select
                h.height,
                temp_head.header_values as temp_header,
                temp_corr.row_values as temp_row,
                speed_head.header_values as speed_header,
                speed_corr.row_values as speed_row,
                dir_corr.row_values[1] as dir_correction
            from calc_correction_heights h
            join calc_correction_types temp_type on temp_type.id = case when v_delta_t0 < 0 then 9 else 8 end
            join calc_correction_headers temp_head on temp_head.id = temp_type.header_id
            join calc_correction temp_corr on temp_corr.height_id = h.id and temp_corr.type_id = temp_type.id
            join calc_correction_types speed_type
                on speed_type.parent_id = 2 and speed_type.measurment_equipment_id = p_equipment_id
            join calc_correction_headers speed_head on speed_head.id = speed_type.header_id
            join calc_correction speed_corr on speed_corr.height_id = h.id and speed_corr.type_id = speed_type.id
            join calc_correction_types dir_type
                on dir_type.parent_id = 3 and dir_type.measurment_equipment_id = p_equipment_id
            join calc_correction dir_corr on dir_corr.height_id = h.id and dir_corr.type_id = dir_type.id
            order by h.height
        loop
            -- Среднее отклонение температуры
            v_delta_t :=
                coalesce(v_rec.temp_row[array_position(v_rec.temp_header, abs(v_delta_t0) / 10 * 10)], 0)
                + coalesce(v_rec.temp_row[array_position(v_rec.temp_header, abs(v_delta_t0) % 10)], 0);

            -- Опорные точки интерполяции
            v_idx_lo := (select count(*) from unnest(v_rec.speed_header) x where x <= v_wind_input);
            v_idx_hi := case
                when v_rec.speed_header[v_idx_lo] = v_wind_input then v_idx_lo
                else v_idx_lo + 1
            end;

            -- Скорость и направление среднего ветра
            if v_idx_lo = 0 then
                v_wind_speed := 0;
                v_wind_dir := 0;
            else
                v_wind_speed := round(calculate_interpolation(
                    v_wind_input,
                    row(
                        v_rec.speed_header[v_idx_lo], v_rec.speed_row[v_idx_lo],
                        v_rec.speed_header[v_idx_hi], v_rec.speed_row[v_idx_hi]
                    )::interpolation_params
                ))::int;
                v_wind_dir := (v_wind_direction + v_rec.dir_correction) % 60;
            end if;

            p_results := p_results || row(
                v_rec.height, meteo_format_h(v_rec.height),
                v_delta_t, meteo_format_tt(v_delta_t),
                v_wind_dir, meteo_format_hh(v_wind_dir),
                v_wind_speed, meteo_format_cc(v_wind_speed)
            )::meteo_height_result;
        end loop;
    end;
    $body$;

end;
$$;