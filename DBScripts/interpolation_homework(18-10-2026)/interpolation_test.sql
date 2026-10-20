-- Тесты функции интерполяции

do $$
declare
    t numeric;
    value numeric;
    expected numeric;
begin
    -- Пример из тз
    select v.t, calculate_interpolation(v.t, get_interpolation_params(v.t)), v.expected
    into t, value, expected
    from (values (23.0, 1.8)) as v(t, expected);
    raise notice 't = %: значение = %, ожидалось = %, %',
        t, value, expected,
        case when value = expected then 'тест пройден' else 'тест не пройден' end;

    -- Свои тесты

    select v.t, calculate_interpolation(v.t, get_interpolation_params(v.t)), v.expected
    into t, value, expected
    from (values (-0.5, 0.25)) as v(t, expected);
    raise notice 't = %: значение = %, ожидалось = %, %',
        t, value, expected,
        case when value = expected then 'тест пройден' else 'тест не пройден' end;

    select v.t, calculate_interpolation(v.t, get_interpolation_params(v.t)), v.expected
    into t, value, expected
    from (values (2.5, 0.5)) as v(t, expected);
    raise notice 't = %: значение = %, ожидалось = %, %',
        t, value, expected,
        case when value = expected then 'тест пройден' else 'тест не пройден' end;

    select v.t, calculate_interpolation(v.t, get_interpolation_params(v.t)), v.expected
    into t, value, expected
    from (values (20.0, 1.5)) as v(t, expected);
    raise notice 't = %: значение = %, ожидалось = %, %',
        t, value, expected,
        case when value = expected then 'тест пройден' else 'тест не пройден' end;

    select v.t, calculate_interpolation(v.t, get_interpolation_params(v.t)), v.expected
    into t, value, expected
    from (values (22.5, 1.75)) as v(t, expected);
    raise notice 't = %: значение = %, ожидалось = %, %',
        t, value, expected,
        case when value = expected then 'тест пройден' else 'тест не пройден' end;

    select v.t, calculate_interpolation(v.t, get_interpolation_params(v.t)), v.expected
    into t, value, expected
    from (values (25.0, 2.0)) as v(t, expected);
    raise notice 't = %: значение = %, ожидалось = %, %',
        t, value, expected,
        case when value = expected then 'тест пройден' else 'тест не пройден' end;

    select v.t, calculate_interpolation(v.t, get_interpolation_params(v.t)), v.expected
    into t, value, expected
    from (values (30.0, 3.5)) as v(t, expected);
    raise notice 't = %: значение = %, ожидалось = %, %',
        t, value, expected,
        case when value = expected then 'тест пройден' else 'тест не пройден' end;

    select v.t, calculate_interpolation(v.t, get_interpolation_params(v.t)), v.expected
    into t, value, expected
    from (values (40.0, 4.5)) as v(t, expected);
    raise notice 't = %: значение = %, ожидалось = %, %',
        t, value, expected,
        case when value = expected then 'тест пройден' else 'тест не пройден' end;
end $$;
