drop table if exists packages cascade;
drop table if exists users cascade;
drop table if exists equipment_type cascade;
drop table if exists parameters cascade;
drop table if exists ranks cascade;


create table equipment_type(
	id int generated always as identity primary key,
	equipment_name text
);

insert into equipment_type (equipment_name) 
values ('ДМК'), ('ВР');


create table users(
    id int generated always as identity primary key,
	full_name text not null
);

insert into users (full_name)
values ('Михаил Вареников Никитич'), ('Максим Болотов Владимирович'),
('Владимир Громов Андреевич'), ('Алексей Королев Дмитриевич');



create table ranks(
	id int generated always as identity primary key,
	rank_name text
);

insert into ranks (rank_name) values ('младший Лейтенант'), ('Рядовой'), ('Генерал'), ('Майор');


create table parameters (
    id int generated always as identity primary key,
	weather_station_height int default 100,
	temperature float default 15,
    pressure int default 750,
	wind_direction int default 0,
	wind_speed int default 0,
	bullet_drift int default 0
);

insert into parameters (weather_station_height, pressure, wind_speed)
values (1233, 747, 12), (133, 767, 18), (1453, 720, 33), (443, 757, 22);

create table packages (
    id int generated always as identity primary key,
	user_id int,
	parameter_id int,
	equipment_id int,
	date timestamp default CURRENT_TIMESTAMP
);

insert into packages(user_id, parameter_id, equipment_id) values
(1, 1, 1), (2, 2, 2), (3, 3, 3);
