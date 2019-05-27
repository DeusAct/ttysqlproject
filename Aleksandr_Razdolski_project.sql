    create schema project;

    -- ID contains only numbers and only 4 numbers
    create domain dom_numericid char(4) check (value ~ '^[0-9]{4}');

    -- Emaili kontroll
    create domain dom_truemail as varchar(320) CHECK (value ~'^[A-Za-z0-9._%\-+!#$&/=?^|~]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');

    -- Ainult t2hed nimis ja Nimi algab suure tähega
    create domain dom_truename as varchar(20) check (value ~ '[a-zA-Z]' and value ~ '^[A-Z]');

    -- Ainult t2hed perekonnanimis ja Perekonnanimi algab suure tähega
    create domain dom_truelastname as varchar(30) check (value ~ '[a-zA-Z]' and value ~ '^[A-Z]');

    -- url valideerimine
    create domain dom_urlcheck as varchar(2083) check (value like 'http://%' or value like 'https://%');

    create table project.Kategooriad
	(
		Kategooria_ID dom_numericid not null primary key,
		Kategooria_nimi varchar(100)
	);

	create table project.Klient
	(
		Klient_ID dom_numericid not null primary key,
		Nimi dom_truename not null,
		Perekonnanimi dom_truelastname not null,
		Aadress varchar(100) not null,
		Tel_number varchar(12) not null,
		Klient_email varchar(320) not null
	);

	create unique index Klient_Tel_number_uindex
		on project.Klient (Tel_number);

	create table project.Ostukorv
	(
		Ostukorv_ID dom_numericid not null primary key,
		Ostukorv_link varchar(2083) not null,
		Soovitus_ID dom_numericid not null references project.Soovitused(soovitus_id),
		KaubaKogus int default 1 not null,
		Toode_ID dom_numericid not null references project.Toode(Toode_ID)
	);

	create table project.Tellimus
	(
		Tellimus_ID dom_numericid not null primary key,
		Klient_ID dom_numericid not null references project.Klient(Klient_ID),
		Aadress_kuhu varchar(100) not null,
		Ostukorv_data varchar(200) not null,
		Tellimuse_staatus varchar(15) not null,
		Date date not null,
		Kohaletootmise_date date not null
	);

    create unique index Tellimus_ID_uindex
	on project.Tellimus (Tellimus_ID);

	create unique index Tellimus_Aadress_kuhu_uindex
		on project.Tellimus (Aadress_kuhu);

	create unique index Tellimus_Ostukorv_data_uindex
		on project.Tellimus (Ostukorv_data);

	create table project.Toode
	(
		Toode_ID dom_numericid not null primary key,
		Kogus int,
		Kategooria_ID dom_numericid not null references project.Kategooriad(Kategooria_ID),
		Kirjeldus text,
		Toode_tyyp varchar(20),
		Toode_nimetus varchar(255) not null,
		Toode_hind int not null,
		Yhik varchar(10) not null,
		Toode_pilt varchar(2083),
		Laoseis int default 0
	);

	create unique index Toode_nimetus_uindex
		on project.Toode (Toode_nimetus);

	create table project.Tootajad
	(
		Tootaja_ID dom_numericid not null primary key,
		Tootaja_nimi dom_truename not null,
		Tootaja_perekonnanimi dom_truelastname not null,
		Tootaja_email varchar(320) not null,
		Tootaja_asukoht varchar(100) not null,
		Tootaja_amet varchar(25) not null
	);


	create table project.Soovitused
	(
		Soovitus_ID dom_numericid not null primary key,
		Tootaja_ID dom_numericid not null references project.Tootajad(tootaja_id),
		Soovitus varchar(255)
	);


--Views--

-- Show workers from Support department
create view vw_supportstaff as
    select *
from project.tootajad
where tootaja_amet = 'Support';

-- Show client shipping data
create view vw_clientshippingdata as
select P.nimi, P.perekonnanimi, P.aadress, P.tel_number, C.date, C.kohaletootmise_date
from project.klient P JOIN project.tellimus C
on P.klient_id = C.klient_id;

-- Show shopping cart comment
create view vw_shoppingcartcomment as
select P.ostukorv_id, P.ostukorv_link, C.soovitus
from project.ostukorv P JOIN project.soovitused C
on P.soovitus_id = C.soovitus_id;

-- Show product which laoseis lower than 5
create view vw_smallquantityproduct as
select toode_nimetus, laoseis
from project.toode
where laoseis < 5;

-- Show orders which made in 2019
create view vw_2019orders as
select tellimus_id, date
from project.tellimus
where date between '2019-01-01' and '2019-12-31';

-- Show orders which status is Completed (Red)
create view vw_readyorders as
select tellimus_id, tellimuse_staatus as Status
from project.tellimus
where tellimuse_staatus = 'Red';


-- Functions


-- Search for product name or pattern
create or replace function get_productname (stoode varchar)
   returns table (toodenimetus varchar) as $$
begin
   return query select
      toode_nimetus
   from
      project.toode
   where
      toode_nimetus ilike stoode;
end;
$$ language plpgsql;


-- Search order by date
create or replace function get_orderdate (sdate varchar)
   returns table (tellimusid int) as $$
begin
   return query select
      tellimus_id::int
   from
      project.tellimus
   where
      date::varchar ilike sdate;
end;
$$ language plpgsql;


-- Update order status
create or replace function update_orderstatus(stellimusid dom_numericid, stellimusestaatus varchar(15))
 returns void as $$
  update project.tellimus
    set tellimuse_staatus = stellimusestaatus
    where tellimus_id = stellimusid;
$$ language sql;


-- Count days from order day to now
create or replace function get_orderwaitingtime(stellimusid varchar)
returns table (tellimusdatediff int) as $$
    begin
    return query select (current_date - date)::int from project.tellimus
        where tellimus_id ILIKE stellimusid;
end; $$ language plpgsql;
