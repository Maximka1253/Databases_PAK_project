do $$
declare
    r record;
begin
    -- Убираем ограничения чтобы можно было вставить ошибочные значения в бд
    for r in
        select conname
        from pg_constraint
        where conrelid = 'parameters'::regclass
        and contype = 'c'
        and pg_get_constraintdef(oid) ilike '%parameter_type_id%'
    loop
        execute format('alter table parameters drop constraint %I', r.conname);
    end loop;

    delete from packages
    where date >= timestamp '2026-10-20 00:00:00'
    and date <  timestamp '2026-10-21 00:00:00';

    with test_packages (full_name, equipment_name, measured_at) as (
        values
        ('Михаил Вареников Никитич', 'ДМК', timestamp '2026-10-20 08:00:00'),
        ('Максим Болотов Владимирович', 'ДМК', timestamp '2026-10-20 09:00:00'),
        ('Владимир Громов Андреевич', 'ДМК', timestamp '2026-10-20 10:00:00'),
        ('Алексей Королев Дмитриевич', 'ВР', timestamp '2026-10-20 11:00:00'),
        ('Дмитрий Соколов Олегович', 'ДМК', timestamp '2026-10-20 13:00:00'),
        ('Игорь Смирнов Александрович', 'ДМК', timestamp '2026-10-20 14:00:00')
    ),
    new_packages as (
        insert into packages (user_id, equipment_id, date)
        select u.id, e.id, tp.measured_at
        from test_packages tp
        join users u on u.full_name = tp.full_name
        join equipment_type e on e.equipment_name = tp.equipment_name
        returning id, date
    )
    insert into parameters (package_id, parameter_type_id, value)
    select np.id, v.parameter_type_id, v.value
    from new_packages np
    join (values
        -- Корректная пачка
        (timestamp '2026-10-20 08:00:00', 1, 100::numeric),
        (timestamp '2026-10-20 08:00:00', 2, 25.0::numeric),
        (timestamp '2026-10-20 08:00:00', 3, 765::numeric),
        (timestamp '2026-10-20 08:00:00', 4, 15::numeric),
        (timestamp '2026-10-20 08:00:00', 5, 6::numeric),

        -- Температура вне диапазона, нет скорости ветра
        (timestamp '2026-10-20 09:00:00', 1, 100::numeric),
        (timestamp '2026-10-20 09:00:00', 2, 75.5::numeric),
        (timestamp '2026-10-20 09:00:00', 3, 760::numeric),
        (timestamp '2026-10-20 09:00:00', 4, 15::numeric),

        -- Давление и скорость ветра вне диапазона
        (timestamp '2026-10-20 10:00:00', 1, 100::numeric),
        (timestamp '2026-10-20 10:00:00', 2, 12.5::numeric),
        (timestamp '2026-10-20 10:00:00', 3, 950::numeric),
        (timestamp '2026-10-20 10:00:00', 4, 20::numeric),
        (timestamp '2026-10-20 10:00:00', 5, 20::numeric),

        -- Направление ветра и снос пуль вне диапазона
        (timestamp '2026-10-20 11:00:00', 1, 150::numeric),
        (timestamp '2026-10-20 11:00:00', 2, 10.0::numeric),
        (timestamp '2026-10-20 11:00:00', 3, 700::numeric),
        (timestamp '2026-10-20 11:00:00', 4, 65::numeric),
        (timestamp '2026-10-20 11:00:00', 6, 200::numeric)  ,

        -- Лишние знаки и недопустимый снос пуль
        (timestamp '2026-10-20 14:00:00', 1, 100.5::numeric),
        (timestamp '2026-10-20 14:00:00', 2, 15.55::numeric),
        (timestamp '2026-10-20 14:00:00', 3, 750::numeric),
        (timestamp '2026-10-20 14:00:00', 4, 10::numeric),
        (timestamp '2026-10-20 14:00:00', 5, 5::numeric),
        (timestamp '2026-10-20 14:00:00', 6, 50::numeric)
    ) as v (measured_at, parameter_type_id, value)
      on v.measured_at = np.date;

end;
$$;