begin;

-- Список параметров с ошибками: только пачки с ошибками.
select *
from get_parameter_errors()
where "Флаг: Есть ошибка";

-- Лучший стрелок: пользователи и количество допущенных ошибок.
select *
from get_best_shooters();

commit;
