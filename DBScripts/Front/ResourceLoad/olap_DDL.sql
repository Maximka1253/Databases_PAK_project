do $$
begin

	-- Еденицы измерения
	begin

		create sequence seq_dim_ranges;
		create table dim_ranges
		(
			id bigint not null primary key default nextval('public.seq_dim_ranges'),
			name text not null,
			factor float
		);

		alter table dim_ranges add constraint uq_dim_ranges_id unique (id);

		comment on table dim_ranges is 'Единицы измерения';
		comment on column dim_ranges.id is 'Внутренний код';
		comment on column dim_ranges.name is 'Название';
		comment on column dim_ranges.factor is 'Коэффициент размера порций)';

	end;

    begin

	-- категории товаров
        create sequence seq_dim_categories;
        create table dim_categories
        (
            id bigint not null primary key default nextval('public.seq_dim_categories'),
            description varchar(255) not null,
            parent_id bigint
        );

        comment on table dim_categories is 'Категории товаров';
        comment on column dim_categories.id is 'Код категории';
        comment on column dim_categories.description is 'Название';
        comment on column dim_categories.parent_id is 'Код родительской категории';

        alter table dim_categories add foreign key (parent_id) references dim_categories (id);
		alter table dim_categories add constraint uq_dim_categories_id unique (id);
	end;

	-- товары
	begin

		create sequence seq_dim_products;
        create table dim_products

        (
            id bigint not null primary key default nextval('public.seq_dim_products'),
            code varchar(255),
            name varchar(255) not null,
            category_id int,
            range_id int
        );

        comment on table dim_products is 'Товары';
        comment on column dim_products.id is 'Код товара';
        comment on column dim_products.code is 'Внешний код товара';
        comment on column dim_products.name is 'Название товара';
        comment on column dim_products.category_id is 'Код категории';
        comment on column dim_products.range_id is 'Код единицы измерения';

        alter table dim_products add foreign key (category_id) references dim_categories (id);
        alter table dim_products add foreign key (range_id) references dim_ranges (id);
		alter table dim_products add constraint uq_dim_products_id unique (id);

	end;

	-- поставщики и группы поставщиков
	begin

		create sequence seq_dim_vendors;
        create table dim_vendors
        (
            id bigint not null primary key default nextval('seq_dim_vendors'),
            clientid varchar(255) not null,
            clientgroup int not null
        );

        create sequence seq_dim_vendorgroup;
        create table dim_vendorgroup
        (
            vendorgroupid int not null primary key,
            description varchar(255)
        );

        alter table dim_vendors add foreign key (clientgroup) references dim_vendorgroup (vendorgroupid);
		alter table dim_vendors add constraint uq_dim_vendors_id unique (id);

	end;

	-- виды оплаты
	begin

		create sequence seq_dim_payment_types;
		create table dim_payment_types
		(
			id bigint not null primary key default nextval('public.seq_dim_payment_types'),
			description varchar(255)
		);

		comment on table dim_payment_types is 'Виды оплаты';
		comment on column dim_payment_types.id is 'Внутренний код';
		comment on column dim_payment_types.description is 'Название';

		alter table dim_payment_types add constraint uq_dim_payment_types_id unique (id);

	end;


	-- сотрудники
	begin

		create sequence seq_dim_employees;
		create table dim_employees
		(
			id bigint not null primary key default nextval('public.seq_dim_employees'),
			firstname varchar(255) not null,
			middlename varchar(255),
			lastname varchar(255)
		);

		alter table dim_employees add constraint uq_dim_employees_id unique (id);

	end;


	-- склады
	begin

		create sequence seq_dim_storages;
		create table dim_storages
		
		(
			id bigint not null primary key default nextval('public.seq_dim_storages'),
			description text not null
		);

		alter table dim_storages add constraint uq_dim_storages_id unique (id);

	end;

	-- причины списания
	begin

		create sequence seq_dim_reason_debit;
		create table dim_reason_debit
		(
			id bigint not null primary key default nextval('public.seq_dim_reason_debit'),
			parent_id bigint,
			description text not null,
			date_add timestamp not null default now()
		);
		
		alter table dim_reason_debit add constraint uq_dim_reasons_id unique (id);
		alter table dim_reason_debit add foreign key (parent_id) references dim_reason_debit (id);

	end;

	commit;
end $$;