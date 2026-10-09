BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Новые пользователи (15 шт., из них 2 заведомо некорректных)
-- Существующие после migration.sql: id 1..4
-- ----------------------------------------------------------------------------
INSERT INTO users (full_name) VALUES
    ('Сергей Петров Иванович'),
    ('Дмитрий Соколов Олегович'),
    ('Игорь Смирнов Александрович'),
    ('Павел Кузнецов Сергеевич'),
    ('Андрей Попов Викторович'),
    ('Николай Лебедев Дмитриевич'),
    ('Олег Морозов Павлович'),
    ('Денис Новиков Андреевич'),
    ('Тимур Ахметов Ренатович'),
    ('Виктор Захаров Николаевич'),
    ('Артём Фёдоров Ильич'),
    ('Евгений Тарасов Геннадьевич'),
    ('Роман Григорьев Олегович'),
    ('12345'),
    ('');

-- ----------------------------------------------------------------------------
-- 2. Новые пачки измерений (20 шт.: 19 с параметрами + 1 пустая)
-- equipment_id: 1 = ДМК, 2 = ВР
-- Даты фиксированные, чтобы параметры ниже могли найти package_id через подзапрос.
-- Существующие после migration.sql: id 1..4 (date = CURRENT_TIMESTAMP на момент миграции)
-- ----------------------------------------------------------------------------
INSERT INTO packages (user_id, equipment_id, date) VALUES
    ((SELECT id FROM users WHERE full_name = 'Сергей Петров Иванович'),      1, TIMESTAMP '2026-01-15 08:30:00'),
    ((SELECT id FROM users WHERE full_name = 'Дмитрий Соколов Олегович'),    1, TIMESTAMP '2026-01-15 09:10:00'),
    ((SELECT id FROM users WHERE full_name = 'Игорь Смирнов Александрович'), 2, TIMESTAMP '2026-01-16 10:15:00'),
    ((SELECT id FROM users WHERE full_name = 'Павел Кузнецов Сергеевич'),    1, TIMESTAMP '2026-02-02 07:45:00'),
    ((SELECT id FROM users WHERE full_name = 'Андрей Попов Викторович'),     2, TIMESTAMP '2026-02-03 11:20:00'),
    ((SELECT id FROM users WHERE full_name = 'Николай Лебедев Дмитриевич'),  1, TIMESTAMP '2026-02-10 06:30:00'),
    ((SELECT id FROM users WHERE full_name = 'Олег Морозов Павлович'),       2, TIMESTAMP '2026-03-01 12:00:00'),
    ((SELECT id FROM users WHERE full_name = 'Денис Новиков Андреевич'),     1, TIMESTAMP '2026-03-05 08:10:00'),
    ((SELECT id FROM users WHERE full_name = 'Тимур Ахметов Ренатович'),      2, TIMESTAMP '2026-03-12 09:40:00'),
    ((SELECT id FROM users WHERE full_name = 'Виктор Захаров Николаевич'),    1, TIMESTAMP '2026-04-01 07:00:00'),
    ((SELECT id FROM users WHERE full_name = 'Артём Фёдоров Ильич'),         2, TIMESTAMP '2026-04-07 14:25:00'),
    ((SELECT id FROM users WHERE full_name = 'Евгений Тарасов Геннадьевич'), 1, TIMESTAMP '2026-05-11 10:00:00'),
    ((SELECT id FROM users WHERE full_name = 'Роман Григорьев Олегович'),    2, TIMESTAMP '2026-05-20 16:30:00'),
    ((SELECT id FROM users WHERE full_name = 'Сергей Петров Иванович'),      2, TIMESTAMP '2026-06-01 09:00:00'),
    ((SELECT id FROM users WHERE full_name = 'Дмитрий Соколов Олегович'),    1, TIMESTAMP '2026-06-15 11:00:00'), -- пачка с BAD-значениями
    ((SELECT id FROM users WHERE full_name = ''),                            1, TIMESTAMP '2026-07-01 08:00:00'), -- BAD: измерение от пустого пользователя
    ((SELECT id FROM users WHERE full_name = 'Павел Кузнецов Сергеевич'),    2, TIMESTAMP '2026-07-02 09:30:00'), -- пачка с BAD-значениями
    ((SELECT id FROM users WHERE full_name = '12345'),                       1, TIMESTAMP '2026-07-03 10:00:00'), -- BAD: измерение от мусорного пользователя
    ((SELECT id FROM users WHERE full_name = 'Николай Лебедев Дмитриевич'),  1, TIMESTAMP '2026-07-04 11:00:00'), -- неполная пачка (только 2 параметра, см. ниже)
    ((SELECT id FROM users WHERE full_name = 'Олег Морозов Павлович'),       1, TIMESTAMP '2026-07-05 12:00:00'); -- BAD: пустая пачка (0 параметров, см. ниже)

-- ----------------------------------------------------------------------------
-- 3. Значения параметров (нормализованная структура после migration2)
-- parameter_type_id: 1=высота, 2=температура, 3=давление,
--                    4=направление ветра, 5=скорость ветра (ДМК), 6=снос пуль (ВР)
-- ----------------------------------------------------------------------------

-- Пачка 2026-01-15 08:30, ДМК, всё корректно
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-15 08:30:00'), 1, 110),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-15 08:30:00'), 2, 12.5),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-15 08:30:00'), 3, 755),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-15 08:30:00'), 4, 15),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-15 08:30:00'), 5, 6);

-- Пачка 2026-01-15 09:10, ДМК, всё корректно (отрицательная температура)
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-15 09:10:00'), 1, 95),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-15 09:10:00'), 2, -3.2),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-15 09:10:00'), 3, 742),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-15 09:10:00'), 4, 30),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-15 09:10:00'), 5, 4);

-- Пачка 2026-01-16 10:15, ВР, всё корректно
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-16 10:15:00'), 1, 130),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-16 10:15:00'), 2, 22.0),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-16 10:15:00'), 3, 758),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-16 10:15:00'), 4, 10),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-01-16 10:15:00'), 6, 85);

-- Пачка 2026-02-02 07:45, ДМК, всё корректно (нулевые ветер)
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-02 07:45:00'), 1, 100),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-02 07:45:00'), 2, 15.0),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-02 07:45:00'), 3, 750),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-02 07:45:00'), 4, 0),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-02 07:45:00'), 5, 0);

-- Пачка 2026-02-03 11:20, ВР, всё корректно
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-03 11:20:00'), 1, 250),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-03 11:20:00'), 2, 5.5),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-03 11:20:00'), 3, 735),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-03 11:20:00'), 4, 45),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-03 11:20:00'), 6, 120);

-- Пачка 2026-02-10 06:30, ДМК, всё корректно
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-10 06:30:00'), 1, 80),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-10 06:30:00'), 2, -12.4),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-10 06:30:00'), 3, 770),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-10 06:30:00'), 4, 22),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-02-10 06:30:00'), 5, 9);

-- Пачка 2026-03-01 12:00, ВР, всё корректно
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-01 12:00:00'), 1, 300),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-01 12:00:00'), 2, 28.3),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-01 12:00:00'), 3, 760),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-01 12:00:00'), 4, 5),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-01 12:00:00'), 6, 40);

-- Пачка 2026-03-05 08:10, ДМК, всё корректно
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-05 08:10:00'), 1, 150),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-05 08:10:00'), 2, 18.7),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-05 08:10:00'), 3, 748),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-05 08:10:00'), 4, 33),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-05 08:10:00'), 5, 7);

-- Пачка 2026-03-12 09:40, ВР, всё корректно
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-12 09:40:00'), 1, 175),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-12 09:40:00'), 2, -5.0),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-12 09:40:00'), 3, 752),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-12 09:40:00'), 4, 27),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-03-12 09:40:00'), 6, 95);

-- Пачка 2026-04-01 07:00, ДМК, всё корректно (пример из ТЗ: 100/25/765/15/6)
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-04-01 07:00:00'), 1, 100),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-04-01 07:00:00'), 2, 25.0),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-04-01 07:00:00'), 3, 765),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-04-01 07:00:00'), 4, 15),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-04-01 07:00:00'), 5, 6);

-- Пачка 2026-04-07 14:25, ВР, всё корректно
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-04-07 14:25:00'), 1, 200),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-04-07 14:25:00'), 2, 10.2),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-04-07 14:25:00'), 3, 743),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-04-07 14:25:00'), 4, 50),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-04-07 14:25:00'), 6, 110);

-- Пачка 2026-05-11 10:00, ДМК, всё корректно
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-05-11 10:00:00'), 1, 90),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-05-11 10:00:00'), 2, 7.8),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-05-11 10:00:00'), 3, 751),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-05-11 10:00:00'), 4, 12),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-05-11 10:00:00'), 5, 3);

-- Пачка 2026-05-20 16:30, ВР, всё корректно
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-05-20 16:30:00'), 1, 140),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-05-20 16:30:00'), 2, -15.6),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-05-20 16:30:00'), 3, 738),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-05-20 16:30:00'), 4, 38),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-05-20 16:30:00'), 6, 65);

-- Пачка 2026-06-01 09:00, ВР, всё корректно (повторный пользователь)
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-06-01 09:00:00'), 1, 105),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-06-01 09:00:00'), 2, 16.4),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-06-01 09:00:00'), 3, 749),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-06-01 09:00:00'), 4, 20),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-06-01 09:00:00'), 6, 70);

-- Пачка 2026-06-15 11:00, ДМК, СОДЕРЖИТ НЕПРАВИЛЬНЫЕ ДАННЫЕ (3 шт.)
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-06-15 11:00:00'), 1, 100),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-06-15 11:00:00'), 2, 75.5),  -- BAD: температура > 58 (макс по ТЗ)
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-06-15 11:00:00'), 3, 760),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-06-15 11:00:00'), 4, 68),   -- BAD: направление ветра > 59
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-06-15 11:00:00'), 5, 25);    -- BAD: скорость ветра > 15

-- Пачка 2026-07-01 08:00, ДМК от пустого пользователя, 1 BAD-значение
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-01 08:00:00'), 1, 120),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-01 08:00:00'), 2, 14.0),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-01 08:00:00'), 3, 455),  -- BAD: давление < 500
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-01 08:00:00'), 4, 10),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-01 08:00:00'), 5, 5);

-- Пачка 2026-07-02 09:30, ВР, СОДЕРЖИТ НЕПРАВИЛЬНЫЕ ДАННЫЕ (3 шт.)
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-02 09:30:00'), 1, 110),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-02 09:30:00'), 2, 20.0),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-02 09:30:00'), 3, 980),  -- BAD: давление > 900
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-02 09:30:00'), 4, -5),   -- BAD: направление ветра < 0
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-02 09:30:00'), 6, 190);  -- BAD: снос пуль > 150

-- Пачка 2026-07-03 10:00, ДМК от мусорного пользователя '12345', 2 BAD-значения
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-03 10:00:00'), 1, 99.99), -- BAD: высота должна быть целым числом
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-03 10:00:00'), 2, -70.0), -- BAD: температура < -58
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-03 10:00:00'), 3, 750),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-03 10:00:00'), 4, 15),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-03 10:00:00'), 5, 2);

-- Пачка 2026-07-04 11:00, ДМК, НЕПОЛНАЯ (BAD по комплектности: всего 2 параметра из 5)
INSERT INTO parameters (package_id, parameter_type_id, value) VALUES
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-04 11:00:00'), 1, 85),
    ((SELECT id FROM packages WHERE date = TIMESTAMP '2026-07-04 11:00:00'), 2, 11.1);
    -- BAD: отсутствуют типы 3 (давление), 4 (направление), 5 (скорость ветра)

COMMIT;