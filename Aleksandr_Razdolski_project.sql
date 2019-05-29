    create schema project;

    -- ID sisaldab ainult 4 numbrit
    create domain dom_numericid char(4) check (value ~ '^[0-9]{4}');

    -- Emaili kontroll
    create domain dom_truemail as varchar(320) CHECK (value ~'^[A-Za-z0-9._%\-+!#$&/=?^|~]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');

    -- Ainult tähed Nimis ja Nimi algab suure tähega
    create domain dom_truename as varchar(20) check (value ~ '[a-zA-Z]' and value ~ '^[A-Z]');

    -- Ainult tähed perekonnanimis ja Perekonnanimi algab suure tähega
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
		Ostukorv_ID dom_numericid not null references project.Ostukorv(Ostukorv_ID),
		Aadress_kuhu varchar(100) not null,
		Tellimuse_staatus varchar(20) not null,
		Date date not null,
		Kohaletootmise_date date not null,
		makse_staatus varchar(15)
	);

    create unique index Tellimus_ID_uindex
	on project.Tellimus (Tellimus_ID);

	create unique index Tellimus_Aadress_kuhu_uindex
		on project.Tellimus (Aadress_kuhu);

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
-- Näita tootajaid Support osakonnast
create view vw_supportstaff as
    select *
from project.tootajad
where tootaja_amet = 'Support';

-- Show client shipping data
-- Näita kliendi kohaletootmise andmed
create view vw_clientshippingdata as
select P.nimi, P.perekonnanimi, P.aadress, P.tel_number, C.date, C.kohaletootmise_date
from project.klient P JOIN project.tellimus C
on P.klient_id = C.klient_id;

-- Show shopping cart comment
-- Näita ostukorvi soovitust
create view vw_shoppingcartcomment as
select P.ostukorv_id, P.ostukorv_link, C.soovitus
from project.ostukorv P JOIN project.soovitused C
on P.soovitus_id = C.soovitus_id;

-- Show products which amount in warehouse lower than 5
-- Näita toodet, mida on laos vähem, kui 5
create view vw_smallquantityproduct as
select toode_nimetus, laoseis
from project.toode
where laoseis < 5;

-- Show orders which made in 2019
-- Näita 2019 aasta tellimusi
create view vw_2019orders as
select tellimus_id, date
from project.tellimus
where date between '2019-01-01' and '2019-12-31';

-- Show orders which status is 'Completed'
-- Näita “'Completed' staatusega tellimusi
create view vw_readyorders as
select tellimus_id, tellimuse_staatus as Status
from project.tellimus
where tellimuse_staatus = 'Red';


-- Functions


-- Search for product name or pattern
-- Otsi toodet nime või mustri järgi
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


-- Search orders by dates
-- Otsi tellimusi kuupäeva järgi
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
-- Värskenda tellimuse järgi
create or replace function update_orderstatus(stellimusid dom_numericid, stellimusestaatus varchar(15))
 returns void as $$
  update project.tellimus
    set tellimuse_staatus = stellimusestaatus
    where tellimus_id = stellimusid;
$$ language sql;


-- Count difference in days between order day and now
-- Loe vahet tellimuse päeva ja tänase kuupäeva vahel päevades
create or replace function get_orderwaitingtime(stellimusid varchar)
returns table (tellimusdatediff int) as $$
    begin
    return query select (current_date - date)::int from project.tellimus
        where tellimus_id ilike stellimusid;
end; $$ language plpgsql;


-- Get worker email by his id
-- Leia töötaja e-mail id järgi
create or replace function get_workeremailbyid(stootajaid varchar)
returns table (workermail varchar) as $$
    begin
        return query select tootaja_email from project.tootajad
        where tootaja_id ilike stootajaid;
    end; $$ language plpgsql;


-- Get product price by id
-- Leia toote hinda id järgi
create or replace function get_productprice(productid varchar)
returns table (price int) as $$
    begin
        return query select toode_hind from project.toode
        where toode_id ilike productid;
    end; $$ language plpgsql;


-- Triggers

-- Deny deletion of orders with status 'In process'
-- Keela 'In process' staatusega tellimuste kustutamist
create or replace function fn_orderdeleteerror() returns trigger as $$
    begin
        if old.tellimuse_staatus like 'In process' then
            raise exception 'You cannot delete order which status is "In process"';
            end if;
            return old;
    end; $$ language plpgsql;

create trigger tr_orderdelete before delete on project.tellimus
    for each row execute procedure fn_orderdeleteerror();


-- Deny deletion of current year orders
-- Keela selle aasta tellimuste kustutamist
create or replace function fn_currentyearorderdel() returns trigger as $$
    begin
        if date_part('year', old.date) = date_part('year', current_date) then
            raise exception 'You cannot delete this year order';
            end if;
            return old;
    end; $$ language plpgsql;

create trigger tr_currentyearorderdel before delete on project.tellimus
    for each row execute procedure fn_currentyearorderdel();


-- Deny order status update if payment status is 'Unpaid'
-- Keela uuendamise kui maksestaatus on 'Unpaid'
create or replace function fn_deny_change_order_without_payment() returns trigger as $$
    begin
        if new.tellimuse_staatus like 'In process' and old.makse_staatus like 'Unpaid' then
            raise exception 'Order status cannot be changed because customer did not paid for order';
        end if;
        return new;
    end; $$ language plpgsql;


create trigger tr_orderwithoutpayment before update on project.tellimus
    for each row execute procedure fn_deny_change_order_without_payment();


-- XML and JSON

-- XML
SELECT query_to_xml('SELECT * FROM project.tellimus', false, false, '');

-- JSON
SELECT row_to_json(tellimus) from project.tellimus;