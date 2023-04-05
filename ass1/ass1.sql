-- Assignment 1 Stage 2
-- Schema for the et.org events/ticketing site
--
-- Written by <<YOUR NAME GOES HERE>>
--
-- Conventions:
-- - all entity table names are plural
-- - most entities have an artifical primary key called "id"
-- - foreign keys are named after the relationship they represent

-- Generally useful domains

create domain URLValue as
	varchar(100) check (value like 'http://%');

create domain EmailValue as
	varchar(100) check (value like '%@%.%');

create domain GenderValue as
	char(1) check (value in ('m','f','n'));

create domain ColourValue as
	char(7) check (value ~ '#[0-9A-Fa-f]{6}');

create domain LocationValue as varchar(40)
	check (value ~ E'^-?\\d+\.\\d+,-?\\d+\.\\d+$');
	-- latitiude and longitude in format used by Google Maps
	-- e.g. '-33.916369,151.23024' (UNSW)

create domain NameValue as varchar(50);

create domain LongNameValue as varchar(100);

create domain ToF_Type as
	boolean check (value in ('y','n'));
create domain ColorsType as
    varchar(10) check (value in ('red','blue','white','black','pink','green','yellow','orange','purple'));
-- PLACES: addresses, geographic locations, etc.

create table Places (
	id          serial, -- integer default nextval('some_seq_or_other')
	name        LongNameValue not null,
	country     NameValue not null,
	addresses   LongNameValue,
	city        NameValue,
	state       NameValue,
	postalCode  integer,
	gpsCoords   LocationValue,
	primary key (id)
);


-- PAGEs: settings for pages in et.org

create table PageColours (
	id          serial,
	u_id        serial,
	name        NameValue not null,
	isTemplate  ToF_Type not null default 'n',
	background  ColorsType default 'black',
	links       ColorsType default 'black',
	boxes       ColorsType default 'white',
	borders     ColorsType default 'black',
	headText    ColorsType default 'white',
	heading     ColorsType default 'white',
	mainText    ColorsType default 'white',
	primary key (id)
);


-- PEOPLE: information about various kinds of people
-- Users are People who can login to the system
-- Contacts are people about whom we have minimal info
-- Organisers are "entities" who organise Events

create table People (
	id          serial,
	email       EmailValue not null unique,
	givenName   NameValue not null,
	familyName  NameValue ,
	primary key (id)
);

create table Users (
	id               serial REFERENCES People(id),
	gender           GenderValue default 'n',
	birthday         date default now(),
	phone            varchar(15),
	blog             URLValue unique,
	website          URLValue unique,
	password         varchar(20) not null,
	showName         NameValue ,
	billingAddress   serial REFERENCES Places(id) not null,
	homeAddress      serial REFERENCES Places(id) ,
	FOREIGN key (billingAddress) REFERENCES Places(id),
	FOREIGN key (homeAddress) REFERENCES Places(id),
	primary key(id)
);
alter table PageColours add constraint fk_u_id foreign key(u_id) REFERENCES Users(id) ;
create table Organisers (
	id              serial,
	u_id            serial REFERENCES Users(id),
	name            LongNameValue not null,
	about           text,
	logo            bytea unique,
	page_id         serial REFERENCES PageColours(id),
	FOREIGN key (page_id) REFERENCES PageColours(id),
	primary key(id)
);

create table ContactLists (
	id         serial,
	name       NameValue not null,
	u_id       serial REFERENCES Users(id) not null,
	FOREIGN key (u_id) REFERENCES Users(id),
	primary key(id)
);

create table MemberofContactLists(
	p_id            serial REFERENCES People(id),
	contact_id      serial REFERENCES ContactLists(id),
	nickName        NameValue ,
	primary key(p_id,contact_id)

);

-- EVENTS: things that happen and which people attend via tickets

create table EventInfo (
	id                 serial,
	title              LongNameValue not null,
	details            text,
	startingTime       time not null,
	duration           interval not null,
	isPrivate          ToF_Type not null default 'y' ,
	showLeft           ToF_Type not null default 'n' ,
	showFee            ToF_Type not null default 'n' ,
	place_id           serial REFERENCES Places(id),            
    Page_id            serial REFERENCES PageColours(id),
	organise_id        serial REFERENCES Organisers(id),
	FOREIGN key (place_id) REFERENCES Places(id),
	FOREIGN key (page_id) REFERENCES PageColours(id),
	FOREIGN key (organise_id) REFERENCES Organisers(id),
	primary key (id)
);

create table Categories(
	e_info_id              serial REFERENCES EventInfo(id),
	categories             NameValue not null,
	primary key (e_info_id,categories)

);


create domain EventRepetitionType as varchar(10)
	check (value in ('daily','weekly','monthly-by-day','monthly-by-date'));

create domain DayOfWeekType as char(3)
	check (value in ('mon','tue','wed','thu','fri','sat','sun'));

create table RepeatingEvents (
	id          serial,
	lowerDate   date not null,
	upperDate   date not null check(upperDate > lowerDate),
	e_info_id   serial REFERENCES EventInfo(id),
	FOREIGN key (e_info_id) REFERENCES EventInfo(id),
	primary key (id)
);

create table Events (
	id                serial,
	startDate         date not null,
	startTime         time not null,
	e_info_id         serial REFERENCES EventInfo(id),
	re_e_id           serial REFERENCES RepeatingEvents(id),
	FOREIGN key (e_info_id) REFERENCES EventInfo(id),
	FOREIGN key (re_e_id) REFERENCES RepeatingEvents(id),
	primary key (id)
);
create table InvitedToEvents(
    p_id        serial REFERENCES People(id),
	e_id        serial REFERENCES Events(id),
	isInvited   ToF_Type not null default 'y',
	primary key (p_id,e_id)
);
create table AttendedToEvents(
    p_id        serial REFERENCES People(id),
	e_id        serial REFERENCES Events(id),
	isAttended   ToF_Type not null default 'y',
	primary key (p_id,e_id)
);
create table DailyEvents (
     id              serial REFERENCES RepeatingEvents(id),
     frequencyType   EventRepetitionType not null,
	 frequency       integer not null check(frequency between 1 and 31),
	 primary key(id)
);
create table WeeklyEvents (
     id              serial REFERENCES RepeatingEvents(id),
	 frequencyType   EventRepetitionType not null,
     frequency       integer not null check(frequency between 1 and 4),
	 dayOfWeek       DayOfWeekType not null, 
	 primary key(id)
);
create table MonthlyByDayEvents (
     id              serial REFERENCES RepeatingEvents(id),
	 frequencyType   EventRepetitionType not null,
     dayOfWeek       DayOfWeekType not null, 
	 weekInMonth     integer not null check(weekInMonth between 1 and 5), 
	 primary key(id)
);
create table MonthlyByDateEvents (
     id              serial REFERENCES RepeatingEvents(id),
	 frequencyType   EventRepetitionType not null,
	 dateInMonth     integer not null check(dateInMonth between 1 and 31), 
	 primary key(id)
);
-- TICKETS: things that let you attend an event
create domain CurrencyTypes as char(3)
       check(value in ('USD','AUD','RMB','EUR'));
create table TicketTypes (
	id          serial,
	e_info_id   serial REFERENCES EventInfo(id),
	price       float not null check(price>0.0),
	currency    CurrencyTypes not null,
	totalNumber integer not null check(totalNumber>0),
	maxPerSale  integer default 1 check(maxPerSale >=1 and maxPerSale <=totalNumber),
	description LongNameValue,
	type        NameValue not null,
    FOREIGN key(e_info_id) REFERENCES EventInfo(id),
	primary key (id)
);
create table SoldTickets(
	id               serial,
	ticketType_id    serial REFERENCES TicketTypes(id),
	p_id             serial REFERENCES People(id),
 	e_id             serial REFERENCES EVENTS(id),
	quantity         integer not null check(quantity>=0),
	FOREIGN key (ticketType_id) REFERENCES TicketTypes(id),
	FOREIGN key (p_id) REFERENCES People(id),
	FOREIGN key (e_id) REFERENCES EVENTS(id),
	primary key (id)

);