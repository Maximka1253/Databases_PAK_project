use Front;

-- Анализ метаданных

-- Таблицы и количество строк
select t.name as table_name,
       sum(p.rows) as row_count
from sys.tables t
join sys.schemas s on s.schema_id = t.schema_id
join sys.partitions p on p.object_id = t.object_id and p.index_id in (0, 1)
group by t.name
order by row_count desc;

-- Внешние ключи
select tp.name as parent_table,
       cp.name as parent_column,
       tr.name as ref_table,
       cr.name as ref_column
from sys.foreign_keys fk
join sys.tables tp on tp.object_id = fk.parent_object_id
join sys.tables tr on tr.object_id = fk.referenced_object_id
join sys.foreign_key_columns fkc on fkc.constraint_object_id = fk.object_id
join sys.columns cp on cp.object_id = fkc.parent_object_id and cp.column_id = fkc.parent_column_id
join sys.columns cr on cr.object_id = fkc.referenced_object_id and cr.column_id = fkc.referenced_column_id
order by tp.name, cp.name;

-- 1. Закупки

-- bm_StorageOperations.VendorID связана с vendors.id (без FK)
select count(*) as Всего,
       count(v.id) as Нашлось
from bm_StorageOperations o
left join vendors v on v.id = o.VendorID
where o.VendorID <> 0;

-- product.SizeID связана с size.ID (без FK)
select count(*) as Всего,
       count(s.ID) as Нашлось
from product p
left join size s on s.ID = p.SizeID;

-- product.vendorid связана с vendors.id (без FK)
select count(*) as Всего,
       count(v.id) as Нашлось
from product p
left join vendors v on v.id = p.vendorid
where p.vendorid <> 0;


-- 2. Продажи

-- journal.id связана с product.productid (без FK)
select count(*) as Всего,
       count(p.id) as Нашлось
from journal j
left join product p on p.productid = j.id;

-- journal.customerid связана с clients.clientid (без FK)
select count(*) as Всего,
       count(c.id) as Нашлось
from journal j
left join clients c on c.clientid = j.customerid;

-- journal.transtype связана с paymenttype.paymenttypeid (без FK)
select count(*) as Всего,
       count(pt.paymenttypeid) as Нашлось
from journal j
left join paymenttype pt on pt.paymenttypeid = j.transtype;

-- bm_Journal_Details.TicketNumber связана с journal.receiptn (без FK)
select count(*) as Всего,
       count(j.receiptn) as Нашлось
from bm_Journal_Details d
left join journal j on j.receiptn = d.TicketNumber;

-- bm_BonusHistory.TicketNumber связана с journal.receiptn (без FK)
select count(*) as Всего,
       count(j.receiptn) as Нашлось
from bm_BonusHistory b
left join journal j on j.receiptn = b.TicketNumber;


-- 3. Поставщики

-- bm_JournalBarnetDocs.TicketNumber связана с journal.receiptn (без FK)
select count(*) as Всего,
       count(j.receiptn) as Нашлось
from bm_JournalBarnetDocs d
left join journal j on j.receiptn = d.TicketNumber;

-- bm_JournalBarnetDocs.PersonID связана с personnel.personid (без FK)
select count(*) as Всего,
       count(p.personid) as Нашлось
from bm_JournalBarnetDocs d
left join personnel p on p.personid = d.PersonID;


-- 4. Персонал

-- personnel.securityaccess связана с securityaccess.securityaccessid (без FK)
select count(*) as Всего,
       count(s.securityaccessid) as Нашлось
from personnel p
left join securityaccess s on s.securityaccessid = p.securityaccess;

-- bm_JournalSessions.PersonID связана с personnel.personid (без FK)
select count(*) as Всего,
       count(p.personid) as Нашлось
from bm_JournalSessions s
left join personnel p on p.personid = s.PersonID;

-- bm_PersonnelSecurity.PersonID связана с personnel.personid (без FK)
select count(*) as Всего,
       count(p.personid) as Нашлось
from bm_PersonnelSecurity x
left join personnel p on p.personid = x.PersonID;


-- 5. Остатки

-- bm_StorageOperations.ReasonID связана с bm_ReasonDebit.ID (без FK)
select count(*) as Всего,
       count(r.ID) as Нашлось
from bm_StorageOperations o
left join bm_ReasonDebit r on r.ID = o.ReasonID
where o.ReasonID <> 0;

-- bm_StorageOperations.BludoID связана с product.id (без FK)
select count(*) as Всего,
       count(p.id) as Нашлось
from bm_StorageOperations o
left join product p on p.id = o.BludoID
where o.BludoID <> 0;

-- bm_Journal_Details.StorageID связана с storages.id (без FK)
select count(*) as Всего,
       count(s.id) as Нашлось
from bm_Journal_Details d
left join storages s on s.id = d.StorageID
where d.StorageID <> 0;
