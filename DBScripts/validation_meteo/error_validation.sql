-- Валидация параметров и функции "Лучший стрелок" и "Список параметров с ошибками"
-- Выполнять после migration_transaction.sql.
do $$
begin

    drop function if exists get_parameter_errors();
    drop function if exists get_best_shooters();
    drop function if exists error_text();
    drop type if exists parameter_list cascade;
    drop type if exists parameter_value cascade;
    drop table if exists parameter_limits cascade;
    drop table if exists parameter_error_types cascade;

    -- Справочник ошибок
    create table parameter_error_types (
        id int generated always as identity primary key,
        code text,
        description text not null
    );

    insert into parameter_error_types (code, description) values
        ('missing', 'Не заполнен обязательный параметр'),
        ('forbidden', 'Параметр недопустим для оборудования'),
        ('out_of_range', 'Значение вне допустимого диапазона'),
        ('invalid_scale', 'Недопустимое число знаков после запятой'),
        ('unknown_parameter', 'Неизвестный тип параметра'),
        ('unknown_equipment', 'Неизвестный тип оборудования');

    -- Допустимые параметры и правила проверки.
    -- Нет строки - параметр недопустим для оборудования.
    create table parameter_limits (
        equipment_id int not null references equipment_type(id) on delete cascade,
        parameter_type_id int not null references parameter_types(id) on delete cascade,
        min_value numeric,
        max_value numeric,
        value_scale smallint not null default 0,
        primary key (equipment_id, parameter_type_id)
    );

    -- Таблица ограничений параметров
    insert into parameter_limits (
        equipment_id, parameter_type_id, min_value, max_value, value_scale
    )
    select
        e.id,
        pt.id,
        v.min_value,
        v.max_value,
        v.value_scale
    from (values
        ('ДМК', 'weather_station_height', null::numeric, null::numeric, 0::smallint),
        ('ДМК', 'temperature', -58::numeric, 58::numeric, 1::smallint),
        ('ДМК', 'pressure', 500::numeric, 900::numeric, 0::smallint),
        ('ДМК', 'wind_direction', 0::numeric, 59::numeric, 0::smallint),
        ('ДМК', 'wind_speed', 0::numeric, 15::numeric, 0::smallint),
        ('ВР', 'weather_station_height', null::numeric, null::numeric, 0::smallint),
        ('ВР', 'temperature', -58::numeric, 58::numeric, 1::smallint),
        ('ВР', 'pressure', 500::numeric, 900::numeric, 0::smallint),
        ('ВР', 'wind_direction', 0::numeric, 59::numeric, 0::smallint),
        ('ВР', 'bullet_drift', 0::numeric, 150::numeric, 0::smallint)
    ) as v (equipment_name, parameter_code, min_value, max_value, value_scale)
    join equipment_type e on e.equipment_name = v.equipment_name
    join parameter_types pt on pt.code = v.parameter_code;

    -- Значения параметров
    create type parameter_value as (
        parameter_type_id int,
        value numeric
    );

    -- Список параметров
    create type parameter_list as (
        equipment_id int,
        parameter_values parameter_value[]
    );

    -- Проверка списка параметров
    create or replace function validate_parameters(p_params parameter_list)
    returns text
    language plpgsql

    as $body$
    declare
        v_errors text := '';
        v_param parameter_value;
        v_name text;
        v_limit parameter_limits%rowtype;
    begin
        if not exists (select 1 from equipment_type where id = p_params.equipment_id) then
            return (
                select description
                from parameter_error_types
                where code = 'unknown_equipment'
            ) || '; ';
        end if;
        -- Основной цикл проверки
        foreach v_param in array coalesce(p_params.parameter_values, array[]::parameter_value[])
        loop
            select name into v_name
            from parameter_types
            where id = v_param.parameter_type_id;

            select * into v_limit
            from parameter_limits
            where equipment_id = p_params.equipment_id
            and parameter_type_id = v_param.parameter_type_id;

            if v_name is null then
                v_errors := v_errors || format(
                    '%s: id=%s; ',
                    (select description from parameter_error_types where code = 'unknown_parameter'),
                    v_param.parameter_type_id
                );
            elsif not found then
                v_errors := v_errors || format(
                    '%s: "%s"; ',
                    (select description from parameter_error_types where code = 'forbidden'),
                    v_name
                );
            elsif v_param.value is null then
                v_errors := v_errors || format(
                    '%s: "%s"; ',
                    (select description from parameter_error_types where code = 'missing'),
                    v_name
                );
            elsif v_param.value <> round(v_param.value, v_limit.value_scale) then
                v_errors := v_errors || format(
                    '%s: "%s" = %s; ',
                    (select description from parameter_error_types where code = 'invalid_scale'),
                    v_name,
                    v_param.value
                );
            elsif (v_limit.min_value is not null and v_param.value < v_limit.min_value)
            or (v_limit.max_value is not null and v_param.value > v_limit.max_value) then
                v_errors := v_errors || format(
                    '%s: "%s" = %s; ',
                    (select description from parameter_error_types where code = 'out_of_range'),
                    v_name,
                    v_param.value
                );
            end if;
        end loop;

        for v_name in
            select pt.name
            from parameter_limits pl
            join parameter_types pt on pt.id = pl.parameter_type_id
            where pl.equipment_id = p_params.equipment_id
            and not exists (
                select 1
                from unnest(coalesce(p_params.parameter_values, array[]::parameter_value[])) pv
                where pv.parameter_type_id = pl.parameter_type_id
            )
        loop
            v_errors := v_errors || format(
                '%s: "%s"; ',
                (select description from parameter_error_types where code = 'missing'),
                v_name
            );
        end loop;

        return nullif(v_errors, '');
    end;
    $body$;

    -- Список параметров с ошибками.
    create or replace function get_best_shooters()
    returns table (
        "Пользователь" text,
        "Количество ошибок" int
    )
    language plpgsql
    as $body$
    begin
        return query
        with errors as (
            -- параметр есть в пакете, но с ошибкой (одна строка = одна ошибка)
            select p.package_id
            from parameters p
            join packages pk on pk.id = p.package_id
            left join parameter_limits pl
                on pl.equipment_id = pk.equipment_id
                and pl.parameter_type_id = p.parameter_type_id
            where pl.parameter_type_id is null  -- недопустим для оборудования
            or p.value <> round(p.value, pl.value_scale)  -- неверное число знаков
            or p.value < pl.min_value or p.value > pl.max_value  -- вне диапазона

            union all

            -- обязательного параметра в пакете нет
            select pk.id
            from packages pk
            join parameter_limits pl on pl.equipment_id = pk.equipment_id
            where not exists (
                select 1
                from parameters p
                where p.package_id = pk.id
                and p.parameter_type_id = pl.parameter_type_id
            )
        )
        select u.full_name, count(e.package_id)::int
        from users u
        left join packages pk on pk.user_id = u.id
        left join errors e on e.package_id = pk.id
        group by u.id, u.full_name
        order by 2, u.full_name;
    end;
    $body$;

    create or replace function get_parameter_errors()
    returns table (
        "№" int,
        "Тип оборудования" text,
        "Высота метеопоста" numeric,
        "Температура" numeric,
        "Давление" numeric,
        "Направление ветра" numeric,
        "Скорость ветра" numeric,
        "Дальность сноса пуль" numeric,
        "Флаг: Есть ошибка" boolean,
        "Описание ошибки" text
    )
    language plpgsql
    as $body$
    begin
        return query
        with checked as (
            -- параметры, которые есть в пакете
            select
                p.package_id,
                p.parameter_type_id,
                pt.name as parameter_name,
                p.value,
                case
                    when pl.parameter_type_id is null then 'forbidden'
                    when p.value <> round(p.value, pl.value_scale) then 'invalid_scale'
                    when p.value < pl.min_value or p.value > pl.max_value then 'out_of_range'
                end as error_code  -- null - ошибки нет
            from parameters p
            join packages pk on pk.id = p.package_id
            join parameter_types pt on pt.id = p.parameter_type_id
            left join parameter_limits pl
                on pl.equipment_id = pk.equipment_id
                and pl.parameter_type_id = p.parameter_type_id

            union all

        -- обязательные параметры, которых в пакете нет
            select pk.id, pl.parameter_type_id, pt.name, null, 'missing'
            from packages pk
            join parameter_limits pl on pl.equipment_id = pk.equipment_id
            join parameter_types pt on pt.id = pl.parameter_type_id
            where not exists (
                select 1
                from parameters p
                where p.package_id = pk.id
                and p.parameter_type_id = pl.parameter_type_id
            )
        ),
        errors as (
            select
                c.package_id,
                string_agg(
                    t.description || ': ' ||
                    case when c.error_code in ('invalid_scale', 'out_of_range')
                        then format('"%s" = %s', c.parameter_name, c.value)
                        else format('"%s"', c.parameter_name)
                    end,
                    '; ' order by c.parameter_type_id
                ) as error_text
            from checked c
            join parameter_error_types t on t.code = c.error_code
            group by c.package_id
        ),
        pivoted as (
            select
                p.package_id,
                max(p.value) filter (where pt.code = 'weather_station_height') as weather_station_height,
                max(p.value) filter (where pt.code = 'temperature') as temperature,
                max(p.value) filter (where pt.code = 'pressure') as pressure,
                max(p.value) filter (where pt.code = 'wind_direction') as wind_direction,
                max(p.value) filter (where pt.code = 'wind_speed') as wind_speed,
                max(p.value) filter (where pt.code = 'bullet_drift') as bullet_drift
            from parameters p
            join parameter_types pt on pt.id = p.parameter_type_id
            group by p.package_id
        )
        select
            pk.id,
            et.equipment_name,
            v.weather_station_height,
            v.temperature,
            v.pressure,
            v.wind_direction,
            v.wind_speed,
            v.bullet_drift,
            e.error_text is not null,
            e.error_text
        from packages pk
        join equipment_type et on et.id = pk.equipment_id
        left join pivoted v on v.package_id = pk.id
        left join errors e on e.package_id = pk.id
        order by pk.id;
    end;
    $body$;

end;
$$;