	create schema project

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
		Seisund varchar(15) not null,
		Date date not null,
		Kohaletootmise_date date not null
	);

	create unique index Tellimus_Aadress_kuhu_uindex
		on project.Tellimus (Aadress_kuhu);

	create unique index Tellimus_Ostukorv_data_uindex
		on project.Tellimus (Ostukorv_data);

	create table project.Toode
	(
		Toode_ID dom_numericid not null primary key,
		Kogus dom_numericid,
		Kategooria_ID dom_numericid not null references project.Kategooriad(Kategooria_ID),
		Kirjeldus text,
		Toode_tyyp varchar(20),
		Toode_nimetus varchar(255) not null,
		Toode_hind dom_numericid not null,
		Yhik varchar(10) not null,
		Toode_pilt varchar(2083),
		Laoseis dom_numericid default 0
	);

	create unique index Toode_Toode_nimetus_uindex
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






-- Emaili kontroll
create domain dom_truemail as varchar(320) CHECK (value ~'^[A-Za-z0-9._%\-+!#$&/=?^|~]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');

-- ID contains only numbers
create domain dom_numericid char(4) check (value ~ '^[0-9]{4}');

-- url valideerimine 

create domain dom_urlcheck as varchar(2083) check (value like 'http://%' or value like 'https://%');

-- Ainult t2hed nimis ja Nimi algab suure tähega
create domain dom_truename as varchar(20) check (value ~ '[a-zA-Z]' and value ~ '^[A-Z]');

-- Ainult t2hed perekonnanimis ja Perekonnanimi algab suure tähega
create domain dom_truelastname as varchar(30) check (value ~ '[a-zA-Z]' and value ~ '^[A-Z]'); 





