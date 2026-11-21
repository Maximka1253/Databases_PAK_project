do $$
declare
	-- Начало и конец диапазона
    date_from constant date := '2012-01-01';
    date_to constant date := '2023-12-31';
begin

    create table dim_time
    (
        id int  not null primary key,
        month_start date not null,
        month_end date not null,
        month_name text not null,
        year int  not null,
        quarter_number int  not null,
        quarter_name text not null
    );

	-- Вставка данных по интервалу из констант

    insert into dim_time (id, month_start, month_end, month_name, year, quarter_number, quarter_name)
    select
        to_char(d, 'YYYYMM')::int,
        d::date,
        (d + interval '1 month - 1 day')::date,
        (array['Январь','Февраль','Март','Апрель','Май','Июнь', 'Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'])[extract(month from d)::int],
        extract(year from d)::int,
        extract(quarter from d)::int,
        extract(quarter from d)::int || ' квартал'
    from generate_series(
        date_trunc('month', date_from),
        date_trunc('month', date_to),
        interval '1 month'
    ) as d;
end $$;