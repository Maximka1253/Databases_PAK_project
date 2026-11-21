do $$
begin

    drop function if exists meteo_bbbtt(numeric, numeric);
    drop function if exists meteo_vvvv(numeric);
    drop function if exists meteo_ddchm(timestamp);
    drop function if exists get_meteo_constant(text);
    drop table if exists meteo_constants cascade;

    -- Таблица метео-констант
    create table meteo_constants (
        code text primary key,
        value numeric not null,
        description text not null
    );

    insert into meteo_constants values
        ('table_pressure', 750, 'Табличное наземное давление, мм рт. ст.'),
        ('table_temperature', 15.9, 'Табличная приземная виртуальная температура, °C'),
        ('negative_pressure_base', 500, 'Префикс отрицательного отклонения давления'),
        ('negative_temperature_base', 50, 'Префикс отрицательной температуры'),
        ('negative_height_base', 5000, 'Префикс отрицательной высоты');

    create or replace function get_meteo_constant(p_code text)
    returns numeric
    language plpgsql

    as $body$
    declare
        v_value numeric;
    begin
        select value into v_value from meteo_constants where code = p_code;
        if not found then
            raise exception 'Константа % не найдена', p_code;
        end if;
        return v_value;
    end;
    $body$;

    -- ДДЧЧМ
    create or replace function meteo_ddchm(p_time timestamp default current_timestamp)
    returns text
    language sql

    as $body$
        select to_char(p_time, 'DDHH24')
            || floor(extract(minute from p_time) / 10)::int::text;
    $body$;

    -- ВВВВ
    create or replace function meteo_vvvv(p_height numeric)
    returns text
    language sql
    
    as $body$
        select lpad(
            case
                when p_height < 0
                    then (get_meteo_constant('negative_height_base') + abs(round(p_height)))::int
                else round(p_height)::int
            end::text,
            4,
            '0'
        );
    $body$;

    -- БББТТ
    create or replace function meteo_bbbtt(p_pressure numeric, p_temperature numeric)
    returns text
    language plpgsql

    as $body$
    declare
        v_dp int := round(p_pressure - get_meteo_constant('table_pressure'))::int;
        v_dt int := round(
            p_temperature + calculate_interpolation(
                p_temperature,
                get_interpolation_params(p_temperature)
            ) - get_meteo_constant('table_temperature')
        )::int;
    begin
        return case
            when v_dp < 0 then (get_meteo_constant('negative_pressure_base') + abs(v_dp))::int::text
            else lpad(v_dp::text, 3, '0')
        end || case
            when v_dt < 0 then lpad((get_meteo_constant('negative_temperature_base') + abs(v_dt))::int::text, 2, '0')
            else lpad(v_dt::text, 2, '0')
        end;
    end;
    $body$;

end;
$$;