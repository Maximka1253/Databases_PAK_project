use Front;

-- Ед измерения
select 'insert into dim_ranges(id, group_id, short_name, description) values ('
    + cast(ID as varchar(max)) + ','
    + cast(GroupID as varchar(max)) + ','''
    + [ShortName] + ''','''
    + [Description] + ''');' 
    as [sql]
 from [bm_classifierSizes]

-- Категории если = 0 то ставим null чтобы не было ошибок при вставке

select 'insert into dim_categories(id, description, parent_id) values ('
    + cast(id as varchar(max)) + ','''   
    + [description] + ''','
    + case 
        when ParentID = 0 then 'null' 
        else cast(ParentID as varchar(max)) 
      end + ');' 
    as [sql]
from [category]


-- Продукты

select 'insert into dim_products(id, code, name, category_id, range_id) values ('
    + cast(id as varchar(max)) + ','''   
    + [productid] + ''',''' +
    + [description] + ''',' +
    + cast(CategoryID as varchar(max)) + ','
    + cast(SizeID as varchar(max)) + ');' 
    as [sql]
 from [product]

-- Поставщики

select 'insert into dim_vendors(id, clientid, clientgroup) values ('
    + cast(id as varchar(max)) + ','''   
    + [clientid] + ''',' +
    + cast(clientgroup as varchar(max)) + ');' 
    as [sql]
 from [vendors]


-- Виды оплат

select 'insert into dim_payment_types(id, description) values ('
    + cast(paymenttypeid as varchar(max)) + ','''   
    + [description] + ''');' 
    as [sql]
 from [paymenttype]


-- Сотрудники

select 'insert into dim_employees(id, firstname, middlename, lastname) values ('
    + cast(personid as varchar(max)) + ','''   
    + [firstname] + ''','''
    + [middlename] + ''','''
    + [lastname] + ''');' 
    as [sql]
 from [personnel]

-- Причины списания также заменяем 0 на null

select 'insert into dim_reason_debit(id, parent_id, description, date_add) values ('
    + cast(ID as varchar(max)) + ',' 
    + case 
        when ParentID = 0 then 'null' 
        else cast(ParentID as varchar(max)) 
      end + ','''
    + [description] + ''','''
    + cast(DateAdd as varchar(max)) + ''');' 
    as [sql]
from [bm_ReasonDebit]