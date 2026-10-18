do $$
begin
    -- Создание типа параметра
    BEGIN
        CREATE TYPE public.interpolation_params AS
        (
            x0 numeric(3, 1),
            y0 numeric(3, 1),
            x1 numeric(3, 1),
            y1 numeric(3, 1)
        );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END;

    ALTER TYPE public.interpolation_params
        OWNER TO postgres;


    CREATE OR REPLACE FUNCTION public.get_interpolation_params(IN temperature numeric)
        RETURNS interpolation_params
        LANGUAGE 'plpgsql'

    AS $BODY$
    declare
        params interpolation_params;
    begin
        -- Проверка допустимого диапазона температуры
        if temperature < -58 or temperature > 58 then
            raise exception 'Температура вне диапазона от -58 до 58';
        end if;

        select
            coalesce(lo.t0, hi.t0), -- x0
            coalesce(lo.delta_tv, hi.delta_tv), -- y0
            coalesce(hi.t0, lo.t0), -- x1
            coalesce(hi.delta_tv, lo.delta_tv) -- y1
        into
            params.x0,
            params.y0,
            params.x1,
            params.y1
        from (select temperature as t) t
        left join lateral (
            select t0, delta_tv
            from temperature_correction
            where t0 <= t.t
            order by t0 desc
            limit 1
        ) lo on true
        left join lateral (
            select t0, delta_tv
            from temperature_correction
            where t0 >= t.t
            order by t0 asc
            limit 1
        ) hi on true;

        return params;
    end;
    $BODY$;

    ALTER FUNCTION public.get_interpolation_params(numeric)
        OWNER TO postgres;


    CREATE OR REPLACE FUNCTION public.calculate_interpolation(IN t numeric, IN params interpolation_params)
        RETURNS numeric
        LANGUAGE 'plpgsql'

    AS $BODY$
    begin
        -- Проверка введенных значений
        if t is null
           or params.x0 is null or params.y0 is null
           or params.x1 is null or params.y1 is null then
            raise exception 'Не заданы входные данные для интерполяции';
        end if;

        -- Если пограничное значение возвращаем y
        if params.x1 = params.x0 then
            return params.y0;
        end if;

        return params.y0 + (t - params.x0) * (params.y1 - params.y0) / (params.x1 - params.x0);
    end;
    $BODY$;

    ALTER FUNCTION public.calculate_interpolation(numeric, interpolation_params)
        OWNER TO postgres;
end $$;