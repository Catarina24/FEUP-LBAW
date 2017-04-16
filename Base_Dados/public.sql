DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
SET SCHEMA 'public';

GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

DROP TABLE IF EXISTS Administrator;

DROP TABLE IF EXISTS Authenticated_User;

DROP TABLE IF EXISTS Category;

DROP TABLE IF EXISTS City;

DROP TABLE IF EXISTS Comments;

DROP TABLE IF EXISTS Country;

DROP TABLE IF EXISTS Event;

DROP TABLE IF EXISTS Event_Content;

DROP TABLE IF EXISTS Guest;

DROP TABLE IF EXISTS Hosts;

DROP TABLE IF EXISTS JoinPoll_UnitToAuthenticated_User;

DROP TABLE IF EXISTS Localization;

DROP TABLE IF EXISTS Meta_Event;

DROP TABLE IF EXISTS Notification;

DROP TABLE IF EXISTS Notification_Intervinient;

DROP TABLE IF EXISTS Paid_Event;

DROP TABLE IF EXISTS Poll;

DROP TABLE IF EXISTS Poll_Unit;

DROP TABLE IF EXISTS Rate;

DROP TABLE IF EXISTS Saved_Event;

DROP TABLE IF EXISTS Ticket;

DROP TABLE IF EXISTS Users;

DROP TABLE IF EXISTS Host;

DROP TABLE IF EXISTS Type_of_Ticket;

CREATE TYPE notification_type AS ENUM(
    'userReport', 'eventReport', 'contentReport', 'eventCommented', 'eventCreatedPoll', 'eventRated', 'eventChangedLocal', 'eventChangedDate', 'eventChangedName', 'eventInvitation', 'eventCanceled', 'eventAllSoldTickets', 'eventReminder', 'userSentEmail'
);

CREATE TYPE recurrence AS ENUM(
	'daily', 'weekly', 'once', 'annually', 'quarterly', 'semester'
);

CREATE TYPE user_state AS ENUM(
	'notConfirmed', 'active', 'canceledAdmin', 'canceledUser'
);

CREATE FUNCTION XOR(bool,bool) RETURNS bool AS '
SELECT ($1 AND NOT $2) OR (NOT $1 AND $2);
' LANGUAGE 'sql';

CREATE TABLE public.Administrator
(
	administrator_id serial PRIMARY KEY,
	username varchar(1000) UNIQUE NOT NULL,
	email varchar(1000) UNIQUE NOT NULL,
	password varchar(1000) NOT NULL,
	active boolean NOT NULL,
	CONSTRAINT min_size CHECK (LENGTH(username) >= 8 AND LENGTH(password) >= 8)
);

CREATE TABLE public.Users
(
	user_id serial PRIMARY KEY,
	first_name varchar(1000) NOT NULL,
	last_name varchar(1000) NOT NULL,
	email varchar(1000) UNIQUE NOT NULL,
	birthdate date,
	nif int UNIQUE,
	CONSTRAINT min_size CHECK (LENGTH(first_name) >= 3 AND LENGTH(last_name) >= 2 AND length(nif::TEXT) = 9),
	CONSTRAINT valid_date CHECK (birthdate < current_date)
);


CREATE TABLE public.Authenticated_User
(
	user_id serial PRIMARY KEY,
	username varchar(1000) UNIQUE NOT NULL,
	password varchar(1000) NOT NULL,
	photo_url varchar(1000),
	user_state user_state NOT NULL,
	FOREIGN KEY(user_id) REFERENCES Users(user_id),
	CONSTRAINT min_size CHECK (LENGTH(username) >= 8 AND LENGTH(password) >= 8)
);

CREATE TABLE public.Category
(
	category_id serial PRIMARY KEY,
	name varchar(1000) UNIQUE NOT NULL
);

CREATE TABLE public.Country
(
	country_id serial PRIMARY KEY,
	name varchar(1000) UNIQUE NOT NULL
);

CREATE TABLE public.City
(
	city_id serial PRIMARY KEY,
	name varchar(1000) NOT NULL,
	country_id integer,
	FOREIGN KEY(city_id) REFERENCES Country(country_id)
);

CREATE TABLE public.Localization
(	
	local_id serial PRIMARY KEY,
    street VARCHAR(1000),
	coordinates VARCHAR(1000) NOT NULL,
	city_id INTEGER,
	FOREIGN KEY(city_id) REFERENCES City(city_id)
);

CREATE TABLE public.Meta_Event
(
	meta_event_id serial PRIMARY KEY,
	name varchar(1000) NOT NULL,
	description varchar(20000) NOT NULL,
	recurrence recurrence NOT NULL,
	meta_event_state boolean NOT NULL,
    photo_url varchar(1000),
	expiration_date timestamp,
	free boolean NOT NULL,
	owner_id integer NOT NULL,
	category_id integer NOT NULL,
	local_id integer NOT NULL,
	FOREIGN KEY(owner_id) REFERENCES Authenticated_User(user_id),
	FOREIGN KEY(category_id) REFERENCES Category(category_id),
	FOREIGN KEY(local_id) REFERENCES Localization(local_id),
	CONSTRAINT expiration_date CHECK (expiration_date > current_date)
);

/*TODO: fazer trigger para quando se adiciona um evento verificar o tipo de meta_event */
CREATE TABLE public.Event
(
	event_id serial PRIMARY KEY,
	name varchar(1000) NOT NULL,
	description varchar(20000) NOT NULL,
	beginning_date timestamp NOT NULL,
	ending_date timestamp,
    event_state boolean NOT NULL,
	photo_url varchar(1000),
	free boolean NOT NULL,
	meta_event_id integer NOT NULL,
	local_id integer NOT NULL,
	FOREIGN KEY(meta_event_id) REFERENCES Meta_Event(meta_event_id),
	FOREIGN KEY(local_id) REFERENCES Localization(local_id),
	/*CONSTRAINT beginning_date CHECK (beginning_date > current_date),*/
	CONSTRAINT end_date CHECK (ending_date > beginning_date)
);

CREATE TABLE public.Event_Content
(
	event_content_id serial PRIMARY KEY,
	user_id integer NOT NULL,
	event_id integer NOT NULL,
	FOREIGN KEY(user_id) REFERENCES Authenticated_User(user_id),
	FOREIGN KEY(event_id) REFERENCES Event(event_id)
);


CREATE TABLE public.Comments
(
	comment_id integer PRIMARY KEY,
	content varchar(10000),
	photo_url varchar(2000),
	comment_date timestamp NOT NULL DEFAULT now(),
	FOREIGN KEY(comment_id) REFERENCES Event_Content(event_content_id),
	CONSTRAINT valid_content CHECK (photo_url IS NOT NULL OR content IS NOT NULL)
);

CREATE TABLE public.Guest
(
	is_going boolean NOT NULL,
	user_id integer,
	event_id integer,
	PRIMARY KEY(user_id, event_id),
	FOREIGN KEY(user_id) REFERENCES Authenticated_User(user_id),
	FOREIGN KEY(event_id) REFERENCES Event(event_id)
);

CREATE TABLE public.Host
(
	user_id integer,
	meta_event_id integer,
	PRIMARY KEY(user_id, meta_event_id),
	FOREIGN KEY(user_id) REFERENCES Authenticated_User(user_id),
	FOREIGN KEY(meta_event_id) REFERENCES Meta_Event(meta_event_id)
);

CREATE TABLE public.Notification
(
	notification_id serial PRIMARY KEY,
	notification_date timestamp NOT NULL DEFAULT now(),
	notification_type notification_type NOT NULL,
	checked boolean NOT NULL, 
	event_id integer,
	event_content_id integer,
	user_id integer,
	administrator_id integer,
	FOREIGN KEY(event_id) REFERENCES Event(event_id),
	FOREIGN KEY(event_content_id) REFERENCES Event_Content(event_content_id),
	FOREIGN KEY(user_id) REFERENCES Authenticated_User(user_id),
	FOREIGN KEY(administrator_id) REFERENCES Administrator(administrator_id),
	CONSTRAINT report CHECK (notification_type IN ('userReport', 'contentReport', 'eventReport') AND administrator_id IS NOT NULL),
	CONSTRAINT valid_user CHECK (XOR(user_id IS NOT NULL, administrator_id IS NOT NULL))
);

CREATE TABLE public.Notification_Intervinient
(
	user_id integer,
	notification_id integer,
	PRIMARY KEY(user_id, notification_id),
	FOREIGN KEY(user_id) REFERENCES Authenticated_User(user_id),
	FOREIGN KEY(notification_id) REFERENCES Notification(notification_id)
);

CREATE TABLE public.Poll
(
	poll_id integer PRIMARY KEY,
	poll_type integer NOT NULL,
	poll_date timestamp NOT NULL DEFAULT now(),
  FOREIGN KEY(poll_id) REFERENCES Event_Content(event_content_id)
);

CREATE TABLE public.Poll_Unit
(
	poll_unit_id serial PRIMARY KEY,
	name varchar(1000) NOT NULL,
	poll_id integer NOT NULL,
	FOREIGN KEY(poll_id) REFERENCES Poll(poll_id)
);

CREATE TABLE public.JoinPoll_UnitToAuthenticated_User
(
  user_id integer,
  poll_unit_id integer,
  PRIMARY KEY(user_id, poll_unit_id),
  FOREIGN KEY(user_id) REFERENCES Authenticated_User(user_id),
  FOREIGN KEY(poll_unit_id) REFERENCES Poll_Unit(poll_unit_id)
);

CREATE TABLE public.Rate
(
	event_content_id integer PRIMARY KEY,
	evaluation integer NOT NULL,
	FOREIGN KEY(event_content_id) REFERENCES Event_Content(event_content_id),
	CONSTRAINT check_evaluation CHECK (evaluation <= 10 AND evaluation > 0)
);

CREATE TABLE public.Saved_Event
(
	user_id integer,
	meta_event_id integer,
	PRIMARY KEY(user_id, meta_event_id),
	FOREIGN KEY(user_id) REFERENCES Authenticated_User(user_id),
	FOREIGN KEY(meta_event_id) REFERENCES Meta_Event(meta_event_id)
);

CREATE TABLE public.Type_of_Ticket
(
	type_of_ticket_id serial PRIMARY KEY,
	ticket_type varchar(1000) NOT NULL,
	price float NOT NULL,
	num_tickets integer NOT NULL,
	meta_event_id integer,
	event_id integer,
	FOREIGN KEY(meta_event_id) REFERENCES Meta_Event(meta_event_id),
	FOREIGN KEY(event_id) REFERENCES Event(event_id),
	CONSTRAINT positive_price CHECK (price > 0),
	CONSTRAINT valid_num_tickets CHECK (num_tickets > 0),
	CONSTRAINT has_event CHECK (meta_event_id IS NOT NULL OR event_id IS NOT NULL)
);

CREATE TABLE public.Ticket
(
	ticket_id serial PRIMARY KEY,
	name varchar(1000) NOT NULL,
	nif integer NOT NULL,
	user_id integer NOT NULL,
	type_of_ticket_id integer NOT NULL,
	FOREIGN KEY(user_id) REFERENCES Users(user_id),
	FOREIGN KEY(type_of_ticket_id) REFERENCES Type_of_Ticket(type_of_ticket_id),
	CONSTRAINT valid_nif CHECK (LENGTH(nif::TEXT) = 9)
);


/* ADMIN */

INSERT INTO public.administrator(username, email, password, active) VALUES ('administrator', 'admin@fe.up.pt', '12345678', true);
INSERT INTO public.administrator(username, email, password, active) VALUES ('administrator2', 'admin2@fe.up.pt', '12345678', true);

/* USER */

INSERT INTO public.users (first_name, last_name, email, nif) VALUES ('Catarina', 'Correia', 'cat@fe.up.pt', 123456789);
INSERT INTO public.users (first_name, last_name, email, nif) VALUES ('Margarida', 'Viterbo', 'viterbo@fe.up.pt', 123456788);
INSERT INTO public.users (first_name, last_name, email, nif) VALUES ('Rui', 'Paiva', 'rvop@fe.up.pt', 123456787);
insert into public.users (first_name, last_name, email, nif) values ('Jack', 'Rivera', 'jrivera0@dyndns.org',    421229203);
insert into public.users (first_name, last_name, email, nif) values ('Anna', 'Murray', 'amurray1@miibeian.gov.cn',    908412251);
insert into public.users (first_name, last_name, email, nif) values ('Irene', 'Austin', 'iaustin2@deliciousdays.com',    422465644);
insert into public.users (first_name, last_name, email, nif) values ('Amanda', 'Moreno', 'amoreno3@noaa.gov',    405653650);
insert into public.users (first_name, last_name, email, nif) values ('Antonio', 'Baker', 'abaker4@ucoz.com',    970469521);
insert into public.users (first_name, last_name, email, nif) values ('Gregory', 'Hunt', 'ghunt5@themeforest.net',    586361299);
insert into public.users (first_name, last_name, email, nif) values ('Johnny', 'Jordan', 'jjordan6@ask.com',    108142558);
insert into public.users (first_name, last_name, email, nif) values ('Emily', 'Moore', 'emoore7@vinaora.com',    490386515);
insert into public.users (first_name, last_name, email, nif) values ('Bonnie', 'Duncan', 'bduncan8@state.gov',    111237423);
insert into public.users (first_name, last_name, email, nif) values ('Justin', 'Parker', 'jparker9@ibm.com',    548570862);
insert into public.users (first_name, last_name, email, nif) values ('Fred', 'Jordan', 'fjordana@rambler.ru',    246114899);
insert into public.users (first_name, last_name, email, nif) values ('Craig', 'Kim', 'ckimb@tamu.edu',    539165690);
insert into public.users (first_name, last_name, email, nif) values ('Judy', 'Parker', 'jparkerc@chronoengine.com',    746236093);
insert into public.users (first_name, last_name, email, nif) values ('David', 'Carpenter', 'dcarpenterd@bluehost.com',    445092791);
insert into public.users (first_name, last_name, email, nif) values ('Julia', 'George', 'jgeorgee@howstuffworks.com',    191336414);
insert into public.users (first_name, last_name, email, nif) values ('Jane', 'Knight', 'jknightf@odnoklassniki.ru',    363968893);
insert into public.users (first_name, last_name, email, nif) values ('Andrew', 'Hunter', 'ahunterg@earthlink.net',    684966657);
insert into public.users (first_name, last_name, email, nif) values ('Tammy', 'James', 'tjamesh@pcworld.com',    743172093);
insert into public.users (first_name, last_name, email, nif) values ('Ashley', 'Cox', 'acoxi@simplemachines.org',    773618442);
insert into public.users (first_name, last_name, email, nif) values ('Fred', 'Russell', 'frussellj@pagesperso-orange.fr',    736142636);
insert into public.users (first_name, last_name, email, nif) values ('Douglas', 'Porter', 'dporterk@cargocollective.com',    938963441);
insert into public.users (first_name, last_name, email, nif) values ('Aaron', 'Sims', 'asimsl@etsy.com',    303255319);
insert into public.users (first_name, last_name, email, nif) values ('Michelle', 'Peters', 'mpetersm@wired.com',    168393307);
insert into public.users (first_name, last_name, email, nif) values ('Andrea', 'Lopez', 'alopezn@psu.edu',    264940387);
insert into public.users (first_name, last_name, email, nif) values ('Michael', 'Burton', 'mburtono@addtoany.com',    247069219);
insert into public.users (first_name, last_name, email, nif) values ('Anne', 'Arnold', 'aarnoldp@seattletimes.com',    269781177);
insert into public.users (first_name, last_name, email, nif) values ('Heather', 'Hunt', 'hhuntq@netvibes.com',    476707865);
insert into public.users (first_name, last_name, email, nif) values ('Diane', 'Warren', 'dwarrenr@china.com.cn',    740430967);
insert into public.users (first_name, last_name, email, nif) values ('Roy', 'James', 'rjamess@bluehost.com',    503900825);
insert into public.users (first_name, last_name, email, nif) values ('Anthony', 'Rose', 'aroset@cdc.gov',    756851186);
insert into public.users (first_name, last_name, email, nif) values ('Jonathan', 'Ramirez', 'jramirezu@bbc.co.uk',    963455641);
insert into public.users (first_name, last_name, email, nif) values ('Dennis', 'Reid', 'dreidv@ucoz.ru',    692773905);
insert into public.users (first_name, last_name, email, nif) values ('Evelyn', 'Jenkins', 'ejenkinsw@ebay.co.uk',    732713202);
insert into public.users (first_name, last_name, email, nif) values ('Barbara', 'Boyd', 'bboydx@oracle.com',    433871379);
insert into public.users (first_name, last_name, email, nif) values ('Emily', 'Ellis', 'eellisy@123-reg.co.uk',    936081895);
insert into public.users (first_name, last_name, email, nif) values ('Bruce', 'Lynch', 'blynchz@google.nl',    163091764);
insert into public.users (first_name, last_name, email, nif) values ('Matthew', 'Hill', 'mhill10@dell.com',    133960861);
insert into public.users (first_name, last_name, email, nif) values ('Daniel', 'Gardner', 'dgardner11@google.ca',    225515650);
insert into public.users (first_name, last_name, email, nif) values ('Philip', 'Martin', 'pmartin12@cnn.com',    473722628);
insert into public.users (first_name, last_name, email, nif) values ('Douglas', 'Lawrence', 'dlawrence13@columbia.edu',    245964531);
insert into public.users (first_name, last_name, email, nif) values ('Louise', 'Bell', 'lbell14@cam.ac.uk',    949922917);
insert into public.users (first_name, last_name, email, nif) values ('Adam', 'Boyd', 'aboyd15@homestead.com',    333991905);
insert into public.users (first_name, last_name, email, nif) values ('Samuel', 'Perkins', 'sperkins16@jimdo.com',    570194051);
insert into public.users (first_name, last_name, email, nif) values ('Christina', 'Lopez', 'clopez17@istockphoto.com',    336883780);
insert into public.users (first_name, last_name, email, nif) values ('Clarence', 'Grant', 'cgrant18@princeton.edu',    140291327);
insert into public.users (first_name, last_name, email, nif) values ('Ernest', 'Phillips', 'ephillips19@google.fr',    397858692);
insert into public.users (first_name, last_name, email, nif) values ('George', 'Porter', 'gporter1a@storify.com',    250004465);
insert into public.users (first_name, last_name, email, nif) values ('Paul', 'Sims', 'psims1b@hubpages.com',    912687307);
insert into public.users (first_name, last_name, email, nif) values ('Helen', 'Berry', 'hberry1c@yale.edu',    688329309);
insert into public.users (first_name, last_name, email, nif) values ('Rachel', 'Fuller', 'rfuller1d@simplemachines.org',    948642665);

/* Authenticated_User */

insert into public.authenticated_user (user_id, username, password, user_state) values (1, 'wdiaz01212', 'eaJ6cjrWd', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (2, 'lperry1fsdf', 'ZtzTfnvsdfsdf', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (3, 'rmontgomeryq', '0VjuEGEF', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (4, 'jriverat', 'ktTk3dsjx', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (5, 'hgreasdene2', 'RssX8YKE3', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (6, 'sray3sdfsdf', 'bVoJ7p9QN', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (7, 'ladams4sdf', 'kX8a60sdf', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (8, 'fpatterson5', '0BMsl16i', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (9, 'jmontgomery6', 'fvcuAnyIST77', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (10, 'jmorrisi', 'yuQRPhYdp6sW', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (11, 'jwashingtony', 'YgG3e7dsdz', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (12, 'pgeorge7', 'ls0VVIiw', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (13, 'blittlev', '8p0JFOJ5Pvc', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (14, 'dfowlerw', 'MW4iS0y6CT', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (15, 'phansen8', 'WnaTHVwC', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (16, 'adundddn9', 'QaJqasdXi', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (17, 'wmontgomerya', 'ectRNdzJ', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (18, 'jowensddab', 'Td4cdsgblf', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (19, 'kalvarezx', 'EZprlYEFP6do', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (20, 'smilleru', 'NMXwxJyltM', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (21, 'rwoodscasdcs', 'Wy5SasdasR8q', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (22, 'phernandezc', 'g8HcQB173ZQt', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (23, 'nweaverr', 'wmPuhezgV', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (24, 'krodriguezd', 'oyfWmIpvwW5', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (25, 'eclarkdse', 'oFMOOuCJhOVE', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (26, 'kmoralesf', '5NaHtxED5d', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (27, 'ktorresg', 'LITQriKzz', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (28, 'jsimmonsh', 't8qMsdsdM2', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (29, 'lbradleyj', 'MIHBmg4Mm', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (30, 'amorgank', 'guLDenHnDV', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (31, 'cramasdosl', 'LPTQk3c5j', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (32, 'wmorrisonm', 'xKubasdasdmcs', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (33, 'prodriguezn', 'XivzYEvW', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (34, 'jyoungasdo', 'Te0vp8LmCW', 'active');
insert into public.authenticated_user (user_id, username, password, user_state) values (35, 'tgonzalezp', '6ZU8Go3M', 'active');


/* Category */

INSERT INTO public.category(name) VALUES ('food');
INSERT INTO public.category(name) VALUES ('economy');
INSERT INTO public.category(name) VALUES ('politics');
INSERT INTO public.category(name) VALUES ('feminism');
INSERT INTO public.category(name) VALUES ('party');

/* Country */

INSERT INTO public.country (name) VALUES ('Portugal');
insert into public.country (name) values ('Vietnam');
insert into public.country (name) values ('China');
insert into public.country (name) values ('Canada');
insert into public.country (name) values ('Russia');
insert into public.country (name) values ('Israel');
insert into public.country (name) values ('Sweden');
insert into public.country (name) values ('Italy');
insert into public.country (name) values ('South Africa');
insert into public.country (name) values ('Spain');
insert into public.country (name) values ('Switzerland');

/* City */

INSERT INTO public.city (name, country_id) VALUES ('Vila Real', 1);
INSERT INTO public.city (name, country_id) VALUES ('Porto', 1);
insert into public.city (name, country_id) values ('Berea', 9);
insert into public.city (name, country_id) values ('Gangmian', 4);
insert into public.city (name, country_id) values ('Liopétri', 5);
insert into public.city (name, country_id) values ('Yaozhuang', 10);
insert into public.city (name, country_id) values ('Hollola', 7);
insert into public.city (name, country_id) values ('Wenwuba', 2);
insert into public.city (name, country_id) values ('Tala', 7);
insert into public.city (name, country_id) values ('Ozimek', 4);
insert into public.city (name, country_id) values ('Bronx', 4);


/* Localization */

INSERT INTO public.localization (coordinates, city_id) VALUES ('41.301035,-7.742235', 1);
INSERT INTO public.localization (coordinates, city_id) VALUES ('-7.742235,41.301035', 2);
INSERT INTO public.localization (coordinates,city_id) VALUES ('-9.67986, 27.56562',4);
INSERT INTO public.localization (coordinates,city_id) VALUES ('-59.24883, -36.37135',11);
INSERT INTO public.localization (coordinates,city_id) VALUES ('16.00633, -81.36173',4);
INSERT INTO public.localization (coordinates,city_id) VALUES ('68.78338, -164.8764',5);
INSERT INTO public.localization (coordinates,city_id) VALUES ('35.69549, -69.3658',11);
INSERT INTO public.localization (coordinates,city_id) VALUES ('-23.16889, -82.92503',7);
INSERT INTO public.localization (coordinates,city_id) VALUES ('54.08318, -119.61063',2);
INSERT INTO public.localization (coordinates,city_id) VALUES ('70.04405, 43.75346',7);
INSERT INTO public.localization (coordinates,city_id) VALUES ('69.38131, -83.91751',9);
INSERT INTO public.localization (coordinates,city_id) VALUES ('-58.18554, 156.59619',10);
INSERT INTO public.localization (coordinates,city_id) VALUES ('0.87103, 3.83657',1);
INSERT INTO public.localization (coordinates,city_id) VALUES ('64.18406, -30.01422',1);
INSERT INTO public.localization (coordinates,city_id) VALUES ('-43.06811, 20.42185',11);
INSERT INTO public.localization (coordinates,city_id) VALUES ('52.16269, -109.28767',4);
INSERT INTO public.localization (coordinates,city_id) VALUES ('75.63733, -176.80829',1);
INSERT INTO public.localization (coordinates,city_id) VALUES ('-14.13524, 161.32212',6);
INSERT INTO public.localization (coordinates,city_id) VALUES ('-7.62238, 118.86011',3);
INSERT INTO public.localization (coordinates,city_id) VALUES ('-14.13902, 164.23161',6);
INSERT INTO public.localization (coordinates,city_id) VALUES ('-88.34669, 73.47526',4);
INSERT INTO public.localization (coordinates,city_id) VALUES ('-14.42082, 36.28037',6);
INSERT INTO public.localization (coordinates,city_id) VALUES ('20.98855, -149.12075',7);
INSERT INTO public.localization (coordinates,city_id) VALUES ('41.45944, -18.49932',10);
INSERT INTO public.localization (coordinates,city_id) VALUES ('41.87926, -14.09907',1);
INSERT INTO public.localization (coordinates,city_id) VALUES ('-19.02655, 107.00858',2);

/* Meta_event */

insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Overhold', 'true', 'Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat. Praesent blandit. Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh. Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo. In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis. Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis. Ut at dolor quis odio consequat varius. Integer ac leo. Pellentesque ultrices mattis odio. Donec vitae nisi. Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla. Sed vel enim sit amet nunc viverra dapibus. Nulla suscipit ligula in lacus. Curabitur at ipsum ac tellus semper interdum. Mauris ullamcorper purus sit amet nulla. Quisque arcu libero, rutrum ac, lobortis vel, dapibus at, diam.', 'once', false, 8, 3, 17);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Overhold', 'true', 'Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.', 'daily', true, 5, 3, 2);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Flexidy', 'true', 'Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh.', 'annually', false, 14, 2, 13);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Sonair', 'true', 'Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci. Mauris lacinia sapien quis libero. Nullam sit amet turpis elementum ligula vehicula consequat. Morbi a ipsum. Integer a nibh. In quis justo. Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet. Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo. Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis. Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem. Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci.', 'daily', true, 33, 4, 13);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Fixflex', 'true', 'Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat. Praesent blandit. Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh. Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo. In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis. Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis. Ut at dolor quis odio consequat varius. Integer ac leo.', 'once', false, 6, 5, 10);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Cookley', 'true', 'Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh. Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo. In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis. Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis. Ut at dolor quis odio consequat varius. Integer ac leo. Pellentesque ultrices mattis odio. Donec vitae nisi. Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla. Sed vel enim sit amet nunc viverra dapibus. Nulla suscipit ligula in lacus. Curabitur at ipsum ac tellus semper interdum. Mauris ullamcorper purus sit amet nulla.', 'once', false, 6, 1, 13);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Hatity', 'true', 'Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat. Praesent blandit. Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum.', 'once', true, 19, 2, 24);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Fintone', 'true', 'In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis. Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis. Ut at dolor quis odio consequat varius.', 'semester', true, 29, 1, 11);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Voyatouch', 'true', 'Curabitur convallis. Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor. Morbi vel lectus in quam fringilla rhoncus. Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci. Mauris lacinia sapien quis libero. Nullam sit amet turpis elementum ligula vehicula consequat. Morbi a ipsum. Integer a nibh. In quis justo. Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet. Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo. Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis.', 'once', true, 20, 1, 16);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Opela', 'true', 'Morbi a ipsum. Integer a nibh. In quis justo. Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet. Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo. Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis. Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem. Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci. Nullam molestie nibh in lectus. Pellentesque at nulla. Suspendisse potenti. Cras in purus eu magna vulputate luctus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem. Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis.', 'once', false, 30, 2, 25);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Job', 'true', 'Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo. Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis. Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem. Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci. Nullam molestie nibh in lectus. Pellentesque at nulla. Suspendisse potenti. Cras in purus eu magna vulputate luctus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem. Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst.', 'once', true, 12, 3, 20);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Zamit', 'true', 'Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat.', 'once', false, 21, 1, 11);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Fixflex', 'true', 'Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor. Morbi vel lectus in quam fringilla rhoncus. Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci. Mauris lacinia sapien quis libero. Nullam sit amet turpis elementum ligula vehicula consequat. Morbi a ipsum. Integer a nibh. In quis justo. Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet. Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo. Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis. Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem. Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci. Nullam molestie nibh in lectus. Pellentesque at nulla. Suspendisse potenti. Cras in purus eu magna vulputate luctus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem. Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh.', 'once', true, 29, 4, 22);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Overhold', 'true', 'Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum.', 'once', true, 9, 4, 20);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Tin', 'true', 'Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum.', 'weekly', false, 5, 1, 9);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Gembucket', 'true', 'Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis. Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem. Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci. Nullam molestie nibh in lectus. Pellentesque at nulla. Suspendisse potenti.', 'once', false, 7, 5, 2);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Tempsoft', 'true', 'Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet.', 'once', false, 31, 1, 7);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Fintone', 'true', 'Nullam molestie nibh in lectus. Pellentesque at nulla. Suspendisse potenti. Cras in purus eu magna vulputate luctus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem. Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat. Praesent blandit. Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh. Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo.', 'once', false, 34, 5, 19);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Greenlam', 'true', 'Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh. Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo. In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis. Donec semper sapien a libero. Nam dui.', 'daily', false, 14, 1, 18);
insert into public.meta_event (name, meta_event_state, description, recurrence, free, owner_id, category_id, local_id) values ('Andalax', 'true', 'Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat. Praesent blandit. Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh. Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo. In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis. Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis. Ut at dolor quis odio consequat varius. Integer ac leo. Pellentesque ultrices mattis odio. Donec vitae nisi. Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla. Sed vel enim sit amet nunc viverra dapibus. Nulla suscipit ligula in lacus. Curabitur at ipsum ac tellus semper interdum. Mauris ullamcorper purus sit amet nulla. Quisque arcu libero, rutrum ac, lobortis vel, dapibus at, diam.', 'once', false, 19, 2, 22);
INSERT INTO public.meta_event (name, meta_event_state, description, recurrence, expiration_date, free, owner_id, category_id, local_id) VALUES ('Dogs', 'true', 'Lets adopt them!', 'daily', TIMESTAMP '2018-05-16 15:36:38', true, 1, 1, 1);
INSERT INTO public.meta_event (name, meta_event_state, description, recurrence, expiration_date, free, owner_id, category_id, local_id) VALUES ('Cats', 'true', 'Lets adopt them!', 'daily', TIMESTAMP '2018-05-16 15:36:38', true, 1, 1, 1);

/* Event */

INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Overhold', 'true', 'Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat. Praesent blandit. Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh. Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo. In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis. Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis. Ut at dolor quis odio consequat varius. Integer ac leo. Pellentesque ultrices mattis odio. Donec vitae nisi. Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla. Sed vel enim sit amet nunc viverra dapibus. Nulla suscipit ligula in lacus. Curabitur at ipsum ac tellus semper interdum. Mauris ullamcorper purus sit amet nulla. Quisque arcu libero, rutrum ac, lobortis vel, dapibus at, diam.', '2016-12-05 02:30:10', '2017-06-15 08:28:16', false, 1, 17);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Overhold', 'true', 'Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.', '2016-05-10 06:43:59', '2017-07-15 04:13:21', true, 2, 2);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Flexidy', 'true', 'Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh.','2016-10-26 13:12:19', '2017-09-02 11:39:01', true, 3, 13);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Sonair', 'true', 'Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci. Mauris lacinia sapien quis libero. Nullam sit amet turpis elementum ligula vehicula consequat. Morbi a ipsum. Integer a nibh. In quis justo. Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet. Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo. Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis. Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem. Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci.', '2016-04-28 20:09:58', '2017-08-16 20:52:03', true, 4, 13);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Fixflex', 'true', 'Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat. Praesent blandit. Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh. Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo. In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis. Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis. Ut at dolor quis odio consequat varius. Integer ac leo.','2016-11-14 08:33:39', '2017-08-05 21:14:54', true, 5, 10);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Cookley', 'true', 'Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh. Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo. In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis. Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis. Ut at dolor quis odio consequat varius. Integer ac leo. Pellentesque ultrices mattis odio. Donec vitae nisi. Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla. Sed vel enim sit amet nunc viverra dapibus. Nulla suscipit ligula in lacus. Curabitur at ipsum ac tellus semper interdum. Mauris ullamcorper purus sit amet nulla.','2016-12-29 15:51:12', '2017-07-06 02:16:33', true, 6, 13);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Hatity', 'true', 'Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat. Praesent blandit. Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum.', '2016-06-10 22:25:30', '2017-11-04 12:17:48', false, 7, 24);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Fintone', 'true', 'In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis. Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis. Ut at dolor quis odio consequat varius.', '2016-11-06 17:46:38', '2017-09-02 04:10:20', false, 8, 11);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Voyatouch', 'true', 'Curabitur convallis. Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor. Morbi vel lectus in quam fringilla rhoncus. Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci. Mauris lacinia sapien quis libero. Nullam sit amet turpis elementum ligula vehicula consequat. Morbi a ipsum. Integer a nibh. In quis justo. Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet. Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo. Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis.', '2016-07-19 23:22:30', '2017-11-22 01:53:38', true, 9, 16);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Opela', 'true', 'Morbi a ipsum. Integer a nibh. In quis justo. Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet. Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo. Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis. Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem. Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci. Nullam molestie nibh in lectus. Pellentesque at nulla. Suspendisse potenti. Cras in purus eu magna vulputate luctus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem. Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis.', '2017-01-04 14:43:39', '2017-09-06 14:05:57', true, 10, 25);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Job', 'true', 'Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo. Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis. Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem. Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci. Nullam molestie nibh in lectus. Pellentesque at nulla. Suspendisse potenti. Cras in purus eu magna vulputate luctus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem. Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst.', '2016-05-18 14:39:10', '2017-06-06 08:30:48', false, 11, 20);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Zamit', 'true', 'Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat.','2017-03-25 18:48:01', '2017-06-24 06:37:40', true, 12, 11);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Fixflex', 'true', 'Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor. Morbi vel lectus in quam fringilla rhoncus. Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci. Mauris lacinia sapien quis libero. Nullam sit amet turpis elementum ligula vehicula consequat. Morbi a ipsum. Integer a nibh. In quis justo. Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet. Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo. Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis. Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem. Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci. Nullam molestie nibh in lectus. Pellentesque at nulla. Suspendisse potenti. Cras in purus eu magna vulputate luctus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem. Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh.', '2016-12-19 23:03:18', '2017-09-17 07:48:16', false, 13, 22);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Overhold', 'true', 'Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum.', '2016-05-29 10:43:33', '2017-08-07 10:00:02', true, 14, 20);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Tin', 'true', 'Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum.', '2016-04-29 00:49:44', '2017-11-26 03:13:00', true, 15, 9);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Gembucket', 'true', 'Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis. Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem. Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci. Nullam molestie nibh in lectus. Pellentesque at nulla. Suspendisse potenti.', '2016-09-29 09:19:26', '2017-05-29 09:58:17', false, 18, 2);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Tempsoft', 'true', 'Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet.', '2016-04-16 18:38:13', '2017-09-03 19:42:54', true, 17, 7);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Fintone', 'true', 'Nullam molestie nibh in lectus. Pellentesque at nulla. Suspendisse potenti. Cras in purus eu magna vulputate luctus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem. Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat. Praesent blandit. Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh. Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo.', '2016-08-21 19:27:06', '2017-09-23 10:52:31', false, 18, 19);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Greenlam', 'true', 'Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh. Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo. In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis. Donec semper sapien a libero. Nam dui.', '2016-08-21 22:27:57', '2017-11-16 21:31:46', true, 19, 18);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Andalax', 'true', 'Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat. Praesent blandit. Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh. Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo. In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis. Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis. Ut at dolor quis odio consequat varius. Integer ac leo. Pellentesque ultrices mattis odio. Donec vitae nisi. Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla. Sed vel enim sit amet nunc viverra dapibus. Nulla suscipit ligula in lacus. Curabitur at ipsum ac tellus semper interdum. Mauris ullamcorper purus sit amet nulla. Quisque arcu libero, rutrum ac, lobortis vel, dapibus at, diam.', '2016-08-21 22:27:57', '2017-11-16 21:31:46', true, 20, 22);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Dogs', 'true', 'Lets adopt them!', '2018-05-14 15:00:00', '2018-05-14 16:00:00', true, 21, 1);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Dogs', 'true', 'Lets adopt them!', '2018-05-15 15:00:00', '2018-05-15 16:00:00', true, 21, 1);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Dogs', 'true', 'Lets adopt them!', '2018-05-16 15:00:00', '2018-05-16 16:00:00', true, 21, 1);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Cats', 'true', 'Lets adopt them!', '2018-05-15 15:00:00', '2018-05-15 16:00:00', true, 22, 2);
INSERT INTO public.event(name, event_state, description, beginning_date, ending_date, free, meta_event_id, local_id) values ('Cats', 'true', 'Lets adopt them!', '2018-05-16 15:00:00', '2018-05-16 16:00:00', true, 22, 2);

/*Event_Content*/

insert into public.event_content (user_id, event_id) values ( 7, 3);
insert into public.event_content (user_id, event_id) values ( 2, 16);
insert into public.event_content (user_id, event_id) values ( 30, 21);
insert into public.event_content (user_id, event_id) values ( 23, 15);
insert into public.event_content (user_id, event_id) values ( 2, 24);
insert into public.event_content (user_id, event_id) values ( 1, 20);
insert into public.event_content (user_id, event_id) values ( 19, 18);
insert into public.event_content (user_id, event_id) values ( 27, 10);
insert into public.event_content (user_id, event_id) values ( 2, 11);
insert into public.event_content (user_id, event_id) values (10, 19);
insert into public.event_content (user_id, event_id) values (21, 7);
insert into public.event_content (user_id, event_id) values (16, 24);
insert into public.event_content (user_id, event_id) values (17, 13);
insert into public.event_content (user_id, event_id) values (26, 15);
insert into public.event_content (user_id, event_id) values (33, 21);
insert into public.event_content (user_id, event_id) values (29, 12);
insert into public.event_content (user_id, event_id) values (23, 24);
insert into public.event_content (user_id, event_id) values (29, 9);
insert into public.event_content (user_id, event_id) values (28, 18);
insert into public.event_content (user_id, event_id) values (26, 8);
insert into public.event_content (user_id, event_id) values (17, 3);
insert into public.event_content (user_id, event_id) values (24, 25);
insert into public.event_content (user_id, event_id) values (1, 19);
insert into public.event_content (user_id, event_id) values (22, 9);
insert into public.event_content (user_id, event_id) values (21, 16);
insert into public.event_content (user_id, event_id) values (10, 8);
insert into public.event_content (user_id, event_id) values (26, 1);
insert into public.event_content (user_id, event_id) values (11, 25);
insert into public.event_content (user_id, event_id) values (1, 16);
insert into public.event_content (user_id, event_id) values (3, 1);
insert into public.event_content (user_id, event_id) values (15, 11);
insert into public.event_content (user_id, event_id) values (18, 12);
insert into public.event_content (user_id, event_id) values (35, 23);
insert into public.event_content (user_id, event_id) values (32, 11);
insert into public.event_content (user_id, event_id) values (4, 4);
insert into public.event_content (user_id, event_id) values (24, 21);
insert into public.event_content (user_id, event_id) values (1, 11);
insert into public.event_content (user_id, event_id) values (25, 17);
insert into public.event_content (user_id, event_id) values (3, 10);
insert into public.event_content (user_id, event_id) values (23, 6);
insert into public.event_content (user_id, event_id) values (4, 24);
insert into public.event_content (user_id, event_id) values (26, 20);
insert into public.event_content (user_id, event_id) values (28, 4);
insert into public.event_content (user_id, event_id) values (1, 24);
insert into public.event_content (user_id, event_id) values (10, 8);
insert into public.event_content (user_id, event_id) values (27, 18);
insert into public.event_content (user_id, event_id) values (11, 15);
insert into public.event_content (user_id, event_id) values (6, 15);
insert into public.event_content (user_id, event_id) values (14, 23);
insert into public.event_content (user_id, event_id) values (3, 7);
insert into public.event_content (user_id, event_id) values (20, 12);
insert into public.event_content (user_id, event_id) values (16, 14);
insert into public.event_content (user_id, event_id) values (1, 9);
insert into public.event_content (user_id, event_id) values (30, 8);
insert into public.event_content (user_id, event_id) values (8, 5);
insert into public.event_content (user_id, event_id) values (21, 2);
insert into public.event_content (user_id, event_id) values (4, 9);
insert into public.event_content (user_id, event_id) values (13, 3);
insert into public.event_content (user_id, event_id) values (11, 20);
insert into public.event_content (user_id, event_id) values (24, 25);
insert into public.event_content (user_id, event_id) values (23, 25);
insert into public.event_content (user_id, event_id) values (2, 25);
insert into public.event_content (user_id, event_id) values (9, 3);
insert into public.event_content (user_id, event_id) values (13, 6);
insert into public.event_content (user_id, event_id) values (10, 5);
insert into public.event_content (user_id, event_id) values (27, 24);
insert into public.event_content (user_id, event_id) values (13, 20);
insert into public.event_content (user_id, event_id) values (31, 3);
insert into public.event_content (user_id, event_id) values (11, 17);
insert into public.event_content (user_id, event_id) values (7, 20);
insert into public.event_content (user_id, event_id) values (3, 4);
insert into public.event_content (user_id, event_id) values (14, 1);
insert into public.event_content (user_id, event_id) values (25, 21);
insert into public.event_content (user_id, event_id) values (27, 12);
insert into public.event_content (user_id, event_id) values (33, 23);
insert into public.event_content (user_id, event_id) values (13, 12);
insert into public.event_content (user_id, event_id) values (20, 19);
insert into public.event_content (user_id, event_id) values (5, 22);
insert into public.event_content (user_id, event_id) values (24, 8);
insert into public.event_content (user_id, event_id) values (35, 15);
insert into public.event_content (user_id, event_id) values (29, 11);
insert into public.event_content (user_id, event_id) values (4, 18);
insert into public.event_content (user_id, event_id) values (31, 16);
insert into public.event_content (user_id, event_id) values (35, 8);
insert into public.event_content (user_id, event_id) values (16, 4);
insert into public.event_content (user_id, event_id) values (4, 12);
insert into public.event_content (user_id, event_id) values (32, 25);
insert into public.event_content (user_id, event_id) values (30, 12);
insert into public.event_content (user_id, event_id) values (16, 22);
insert into public.event_content (user_id, event_id) values (10, 14);
insert into public.event_content (user_id, event_id) values (11, 16);
insert into public.event_content (user_id, event_id) values (28, 6);
insert into public.event_content (user_id, event_id) values (19, 3);
insert into public.event_content (user_id, event_id) values (10, 20);
insert into public.event_content (user_id, event_id) values (21, 3);
insert into public.event_content (user_id, event_id) values (19, 8);
insert into public.event_content (user_id, event_id) values (13, 11);
insert into public.event_content (user_id, event_id) values (27, 6);
insert into public.event_content (user_id, event_id) values (20, 11);
insert into public.event_content (user_id, event_id) values (29, 5);

/*Type_of_ticket */
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (1, 'enim', 37.53, 470, 13,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (2, 'mauris', 28.7, 33, 12,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (3, 'tristique', 88.25, 186, 4,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (4, 'felis', 20.45, 397, 15,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (5, 'sollicitudin', 18.09, 398, 14,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (6, 'elit', 99.85, 418, 3,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (7, 'lobortis', 45.41, 232, 3,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (8, 'donec', 94.47, 81, 22,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (9, 'nec', 5.25, 26, 6,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (10, 'lorem', 16.59, 468, 8,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (11, 'mauris', 12.26, 410, 16,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (12, 'pretium', 36.7, 217, 16,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (13, 'luctus', 11.06, 200, 14,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (14, 'mauris', 83.11, 489, 21,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (15, 'eros', 25.15, 262, 12,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (16, 'in', 27.6, 292, 19,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (17, 'vel', 91.26, 409, 3,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (18, 'et', 28.16, 77, 13,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (19, 'semper', 45.41, 52, 18,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (20, 'luctus', 11.39, 265, 22,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (21, 'integer', 95.59, 430, 18,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (22, 'nunc', 78.19, 308, 20,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (23, 'porta', 21.01, 424, 22,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (24, 'vulputate', 33.27, 146, 8,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (25, 'in', 52.48, 448, 20,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (26, 'in', 12.3, 114, 2,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (27, 'congue', 21.1, 119, 18,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (28, 'in', 10.74, 100, 6,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (29, 'vitae', 39.95, 275, 4,NULL);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (30, 'consequat', 64.38, 469,NULL, 4);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (31, 'id', 91.89, 408,NULL, 3);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (32, 'aliquam', 94.78, 37,NULL, 20);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (33, 'lorem', 80.61, 406,NULL, 7);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (34, 'sed', 25.38, 23,NULL, 16);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (35, 'massa', 33.77, 206,NULL, 7);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (36, 'quis', 66.58, 27,NULL, 22);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (37, 'potenti', 75.67, 266,NULL, 21);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (38, 'viverra', 13.8, 176,NULL, 4);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (39, 'vitae', 44.63, 440,NULL, 3);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (40, 'pellentesque', 89.7, 127,NULL, 15);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (41, 'molestie', 10.87, 464,NULL, 24);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (42, 'morbi', 40.08, 423,NULL, 8);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (43, 'sed', 66.48, 259,NULL, 4);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (44, 'urna', 89.5, 464,NULL, 18);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (45, 'sapien', 44.59, 428,NULL, 8);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (46, 'justo', 35.11, 183,NULL, 6);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (47, 'dapibus', 42.55, 34,NULL, 9);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (48, 'in', 87.39, 305,NULL, 17);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (49, 'pellentesque', 86.32, 94,NULL, 18);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (50, 'tortor', 14.88, 392,NULL, 22);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (51, 'et', 62.62, 211,NULL, 16);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (52, 'morbi', 87.34, 385,NULL, 5);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (53, 'sit', 51.95, 66,NULL, 18);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (54, 'luctus', 30.44, 298,NULL, 5);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (55, 'semper', 32.62, 210,NULL, 19);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (56, 'sem', 11.49, 43,NULL, 4);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (57, 'sed', 41.35, 420,NULL, 7);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (58, 'aliquam', 66.29, 330,NULL, 5);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (59, 'cras', 86.86, 164,NULL, 18);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (60, 'in', 16.86, 308,NULL, 4);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (61, 'lacus', 92.39, 30,NULL, 18);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (62, 'praesent', 32.77, 112,NULL, 10);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (63, 'semper', 46.49, 138,NULL, 1);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (64, 'sollicitudin', 8.12, 142,NULL, 10);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (65, 'luctus', 38.72, 311,NULL, 21);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (66, 'luctus', 84.12, 100,NULL, 14);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (67, 'lorem', 34.71, 18,NULL, 13);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (68, 'semper', 6.4, 147,NULL, 4);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (69, 'nibh', 20.53, 480,NULL, 22);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (70, 'mi', 29.06, 50,NULL, 15);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (71, 'felis', 66.72, 7,NULL, 13);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (72, 'libero', 87.99, 409,NULL, 21);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (73, 'ipsum', 20.6, 408,NULL, 21);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (74, 'maecenas', 27.89, 175,NULL, 17);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (75, 'ipsum', 82.49, 61,NULL, 2);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (76, 'et', 52.29, 289,NULL, 15);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (77, 'aenean', 90.88, 309,NULL, 17);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (78, 'quisque', 71.59, 123,NULL, 2);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (79, 'lectus', 13.98, 14,NULL, 15);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (80, 'nec', 73.04, 172,NULL, 6);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (81, 'interdum', 53.68, 41,NULL, 9);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (82, 'ultrices', 51.03, 311,NULL, 14);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (83, 'non', 90.63, 203,NULL, 1);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (84, 'nulla', 29.63, 420,NULL, 18);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (85, 'odio', 51.53, 446,NULL, 16);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (86, 'sed', 89.77, 426,NULL, 12);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (87, 'platea', 39.31, 65,NULL, 1);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (88, 'quam', 6.56, 312,NULL, 9);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (89, 'ante', 58.78, 403,NULL, 14);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (90, 'elit', 45.29, 273,NULL, 24);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (91, 'cubilia', 70.68, 190,NULL, 14);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (92, 'dapibus', 39.9, 87,NULL, 16);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (93, 'maecenas', 21.32, 47,NULL, 17);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (94, 'nec', 44.5, 335,NULL, 21);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (95, 'nibh', 89.54, 463,NULL, 3);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (96, 'condimentum', 15.49, 202,NULL, 19);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (97, 'porta', 47.53, 399,NULL, 7);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (98, 'aliquet', 33.03, 471,NULL, 18);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (99, 'sed', 50.81, 400,NULL, 7);
insert into public.type_of_ticket (type_of_ticket_id, ticket_type, price, num_tickets, meta_event_id, event_id) values (100, 'potenti', 98.0, 164,NULL, 10);

/*Ticket */
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (1, 733822337, 'montes nascetur ridiculus mus', 15, 87);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (2, 804729173, 'in quam fringilla', 6, 3);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (3, 309679323, 'turpis nec euismod scelerisque', 5, 40);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (4, 729134566, 'vulputate vitae', 25, 33);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (5, 683398955, 'venenatis turpis', 6, 61);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (6, 689492103, 'sapien ut nunc vestibulum', 3, 32);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (7, 298079357, 'in faucibus orci luctus', 34, 44);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (8, 785070399, 'enim sit', 11, 92);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (9, 816789177, 'mauris non ligula pellentesque', 8, 74);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (10, 756525272, 'nullam varius', 3, 52);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (11, 792716859, 'ut nulla', 3, 36);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (12, 343713099, 'morbi porttitor lorem', 13, 22);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (13, 505529448, 'ac diam cras pellentesque', 7, 27);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (14, 232320507, 'praesent lectus vestibulum quam', 15, 43);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (15, 418440953, 'imperdiet et', 27, 18);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (16, 621885207, 'turpis elementum', 5, 12);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (17, 545950324, 'blandit ultrices enim', 25, 62);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (18, 497455079, 'cras non', 25, 36);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (19, 978492653, 'viverra pede ac diam', 25, 2);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (20, 392854383, 'dui maecenas tristique est', 21, 37);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (21, 176201579, 'nibh in quis justo', 23, 52);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (22, 312790328, 'nulla sed vel enim', 30, 36);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (23, 472936995, 'purus sit amet', 13, 90);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (24, 939612617, 'nulla justo aliquam', 12, 2);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (25, 403470443, 'turpis a pede posuere', 14, 76);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (26, 215720510, 'suspendisse accumsan', 17, 45);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (27, 748021007, 'maecenas tincidunt lacus at', 19, 42);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (28, 155083859, 'vitae nisi', 29, 80);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (29, 727736191, 'odio cras mi', 3, 82);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (30, 508003751, 'maecenas tincidunt lacus', 28, 77);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (31, 255752643, 'sapien ut', 28, 65);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (32, 339339961, 'quisque ut', 24, 92);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (33, 248229725, 'quam a odio', 34, 55);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (34, 291594521, 'metus sapien ut nunc', 14, 11);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (35, 892485876, 'massa id nisl venenatis', 13, 37);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (36, 555042071, 'dignissim vestibulum vestibulum ante', 18, 44);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (37, 871698502, 'accumsan odio curabitur', 13, 61);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (38, 677425350, 'quis libero nullam sit', 26, 1);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (39, 787753796, 'in lacus curabitur at', 22, 14);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (40, 714487795, 'curabitur gravida nisi', 15, 21);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (41, 615607522, 'curae duis faucibus accumsan', 5, 2);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (42, 621134710, 'a nibh in', 33, 100);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (43, 742562860, 'vivamus vel nulla eget', 4, 56);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (44, 557464541, 'accumsan odio curabitur', 7, 22);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (45, 719237143, 'nisl nunc nisl duis', 35, 96);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (46, 229630333, 'in faucibus orci', 29, 7);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (47, 379089118, 'quam nec dui', 14, 32);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (48, 521676910, 'non velit donec', 21, 9);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (49, 581315866, 'interdum eu tincidunt', 3, 44);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (50, 341443300, 'donec vitae', 35, 5);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (51, 648158742, 'vel pede morbi porttitor', 16, 32);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (52, 958690116, 'ipsum dolor sit', 8, 56);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (53, 663860756, 'nibh fusce', 28, 92);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (54, 426224634, 'gravida nisi at nibh', 22, 80);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (55, 374162636, 'purus eu magna vulputate', 22, 70);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (56, 140106220, 'non velit donec diam', 19, 31);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (57, 450604383, 'nec molestie', 28, 16);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (58, 390239380, 'ante nulla', 7, 51);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (59, 566363060, 'metus arcu', 9, 13);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (60, 620223027, 'non lectus aliquam sit', 4, 68);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (61, 496363074, 'mauris morbi', 27, 34);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (62, 317209903, 'suspendisse potenti nullam', 12, 44);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (63, 909922824, 'ac lobortis vel', 22, 34);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (64, 122829328, 'tempor turpis nec', 32, 70);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (65, 315632425, 'vestibulum ante ipsum primis', 17, 38);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (66, 558996434, 'quis odio', 34, 73);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (67, 867974579, 'a ipsum', 13, 41);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (68, 737766575, 'est quam', 17, 62);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (69, 711162064, 'erat fermentum', 2, 56);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (70, 134720387, 'amet eleifend pede', 30, 82);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (71, 926277699, 'lacus at turpis', 25, 63);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (72, 380453347, 'augue vel', 26, 92);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (73, 410404419, 'adipiscing molestie', 11, 22);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (74, 959561395, 'volutpat quam pede', 11, 72);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (75, 828640606, 'duis bibendum', 14, 92);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (76, 865776805, 'placerat praesent', 7, 99);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (77, 486450583, 'ipsum integer a', 26, 86);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (78, 562831734, 'sed magna at', 21, 10);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (79, 151743961, 'nulla facilisi cras', 23, 58);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (80, 180413963, 'nullam varius nulla facilisi', 34, 35);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (81, 494126889, 'odio donec', 9, 17);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (82, 404536402, 'non ligula pellentesque ultrices', 28, 82);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (83, 969132044, 'tempor convallis nulla', 5, 57);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (84, 241945560, 'odio cras mi pede', 20, 21);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (85, 532226546, 'vivamus in felis eu', 24, 19);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (86, 699285446, 'libero non', 26, 13);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (87, 128278474, 'vestibulum proin', 20, 34);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (88, 323659240, 'sapien cursus vestibulum proin', 4, 19);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (89, 147981961, 'sed tristique in tempus', 3, 76);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (90, 507551520, 'penatibus et magnis', 11, 84);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (91, 371135684, 'sem duis aliquam', 30, 39);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (92, 652218745, 'sed sagittis', 17, 77);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (93, 221182221, 'curabitur convallis', 30, 20);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (94, 668859021, 'in faucibus orci', 24, 2);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (95, 651824308, 'elementum nullam varius nulla', 5, 89);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (96, 610374904, 'non velit nec nisi', 14, 7);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (97, 757776192, 'lacinia nisi venenatis tristique', 29, 25);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (98, 919699022, 'mus etiam vel augue', 19, 3);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (99, 556886166, 'in felis donec semper', 34, 36);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (100, 401495237, 'pretium nisl ut volutpat', 22, 24);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (101, 565406579, 'turpis enim', 7, 31);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (102, 597276524, 'lobortis sapien', 1, 67);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (103, 271342030, 'nulla dapibus dolor', 31, 37);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (104, 847895909, 'erat fermentum justo', 19, 95);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (105, 129773937, 'vivamus in felis eu', 7, 14);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (106, 422417795, 'sollicitudin mi sit amet', 33, 46);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (107, 153684461, 'lorem id ligula suspendisse', 1, 82);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (108, 133419078, 'feugiat et', 4, 45);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (109, 310960206, 'vitae mattis nibh', 34, 81);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (110, 221485722, 'lectus pellentesque at nulla', 10, 94);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (111, 682762326, 'tristique est et', 1, 13);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (112, 606818596, 'arcu sed augue aliquam', 13, 21);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (113, 313847201, 'duis mattis', 13, 87);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (114, 799299210, 'arcu libero rutrum ac', 5, 82);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (115, 948165718, 'in quam fringilla rhoncus', 18, 4);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (116, 649795785, 'dui maecenas', 32, 32);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (117, 360482707, 'tempus vel pede', 28, 83);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (118, 262941516, 'nulla suscipit ligula', 31, 38);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (119, 827417950, 'congue elementum in hac', 9, 75);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (120, 761862360, 'tellus semper interdum mauris', 22, 37);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (121, 200095336, 'dui luctus rutrum nulla', 17, 6);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (122, 147856506, 'mi in porttitor pede', 34, 34);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (123, 661507595, 'integer ac neque duis', 30, 58);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (124, 553753595, 'blandit nam nulla', 35, 89);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (125, 203249726, 'vestibulum ante ipsum', 35, 74);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (126, 746654386, 'nulla justo aliquam quis', 20, 69);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (127, 959390764, 'lectus pellentesque eget', 2, 84);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (128, 813397732, 'amet lobortis', 20, 24);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (129, 322344286, 'erat id mauris', 20, 95);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (130, 582631086, 'libero nam dui', 27, 54);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (131, 268111373, 'dictumst aliquam augue quam', 7, 36);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (132, 455357371, 'justo in', 10, 73);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (133, 874436750, 'amet justo morbi', 15, 69);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (134, 878521631, 'consequat dui', 13, 15);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (135, 564708220, 'euismod scelerisque', 31, 64);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (136, 917476313, 'sit amet', 16, 35);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (137, 623542996, 'volutpat convallis morbi odio', 33, 75);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (138, 964984993, 'diam cras', 18, 78);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (139, 425848119, 'eu tincidunt in leo', 9, 4);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (140, 521181833, 'lectus vestibulum', 21, 29);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (141, 544373823, 'nam dui', 33, 61);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (142, 995248013, 'consequat varius integer', 27, 51);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (143, 781981296, 'in blandit ultrices enim', 18, 97);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (144, 173267175, 'tellus semper', 23, 95);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (145, 468909050, 'natoque penatibus et magnis', 18, 69);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (146, 811610744, 'est quam', 5, 55);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (147, 493768454, 'posuere cubilia curae duis', 30, 31);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (148, 235252765, 'odio elementum eu', 13, 22);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (149, 302527484, 'varius integer', 20, 67);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (150, 530883397, 'sed lacus morbi sem', 35, 74);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (151, 423204921, 'commodo vulputate justo in', 26, 47);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (152, 190756528, 'nibh fusce', 18, 32);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (153, 293735559, 'in libero ut', 27, 52);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (154, 174551971, 'morbi porttitor lorem', 6, 98);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (155, 579052880, 'id ligula suspendisse ornare', 1, 49);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (156, 252157524, 'interdum eu tincidunt', 30, 28);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (157, 726986031, 'consequat lectus', 13, 35);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (158, 994617735, 'ipsum ac tellus', 27, 97);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (159, 892629973, 'iaculis diam erat', 11, 46);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (160, 242996060, 'magna at', 8, 88);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (161, 219013429, 'ultrices aliquet', 31, 47);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (162, 765681983, 'cubilia curae nulla', 31, 22);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (163, 576257974, 'ipsum primis in', 12, 92);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (164, 184512937, 'odio condimentum id luctus', 25, 60);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (165, 105459584, 'ornare imperdiet sapien', 23, 30);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (166, 528619231, 'molestie lorem quisque', 13, 10);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (167, 550018030, 'id pretium', 11, 66);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (168, 188142090, 'blandit ultrices enim', 21, 79);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (169, 455595140, 'nullam porttitor lacus', 26, 45);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (170, 893403381, 'arcu libero rutrum ac', 35, 22);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (171, 501996451, 'porttitor pede justo eu', 18, 55);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (172, 865145880, 'at velit eu', 28, 93);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (173, 136096598, 'nullam orci', 22, 17);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (174, 901929582, 'dapibus at diam nam', 13, 44);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (175, 308031935, 'duis consequat dui nec', 4, 40);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (176, 848665252, 'mattis egestas metus', 1, 99);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (177, 770781902, 'tempor turpis nec', 4, 21);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (178, 483085621, 'vestibulum sagittis', 22, 73);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (179, 512066669, 'vulputate justo in', 4, 48);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (180, 563202526, 'non ligula pellentesque ultrices', 23, 83);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (181, 370228209, 'at feugiat non', 25, 22);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (182, 521258346, 'id turpis integer aliquet', 6, 57);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (183, 709409468, 'lacus morbi quis', 7, 54);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (184, 411806578, 'suscipit a feugiat et', 23, 18);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (185, 547368004, 'nulla tempus vivamus', 20, 22);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (186, 944879594, 'ante ipsum', 21, 12);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (187, 399614647, 'vitae ipsum aliquam non', 35, 89);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (188, 445245168, 'leo pellentesque', 20, 81);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (189, 917958150, 'lectus pellentesque eget', 20, 50);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (190, 894175763, 'dolor vel est donec', 8, 96);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (191, 177538068, 'sed augue', 21, 66);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (192, 242738725, 'posuere cubilia curae', 17, 91);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (193, 943360882, 'hac habitasse', 1, 30);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (194, 199406906, 'morbi quis', 8, 74);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (195, 317041038, 'lorem ipsum dolor sit', 32, 23);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (196, 979276260, 'nulla ut', 24, 37);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (197, 753542941, 'tristique in tempus sit', 15, 50);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (198, 585312945, 'suspendisse ornare consequat', 13, 44);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (199, 445614104, 'id consequat', 4, 36);
insert into public.ticket (ticket_id, nif, name, user_id, type_of_ticket_id) values (200, 384341903, 'felis sed interdum', 22, 83);

/*GUEST*/

insert into public.Guest (is_going, user_id, event_id) values (false, 10, 9);
insert into public.Guest (is_going, user_id, event_id) values (true, 21, 15);
insert into public.Guest (is_going, user_id, event_id) values (true, 29, 17);
insert into public.Guest (is_going, user_id, event_id) values (true, 23, 2);
insert into public.Guest (is_going, user_id, event_id) values (false, 7, 16);
insert into public.Guest (is_going, user_id, event_id) values (true, 6, 15);
insert into public.Guest (is_going, user_id, event_id) values (true, 4, 19);
insert into public.Guest (is_going, user_id, event_id) values (false, 18, 3);
insert into public.Guest (is_going, user_id, event_id) values (true, 7, 2);
insert into public.Guest (is_going, user_id, event_id) values (true, 13, 15);
insert into public.Guest (is_going, user_id, event_id) values (true, 7, 4);
insert into public.Guest (is_going, user_id, event_id) values (false, 21, 3);
insert into public.Guest (is_going, user_id, event_id) values (true, 10, 3);
insert into public.Guest (is_going, user_id, event_id) values (true, 35, 15);
insert into public.Guest (is_going, user_id, event_id) values (false, 9, 18);
insert into public.Guest (is_going, user_id, event_id) values (true, 20, 22);
insert into public.Guest (is_going, user_id, event_id) values (true, 22, 3);
insert into public.Guest (is_going, user_id, event_id) values (false, 28, 3);
insert into public.Guest (is_going, user_id, event_id) values (false, 16, 13);
insert into public.Guest (is_going, user_id, event_id) values (true, 14, 12);
insert into public.Guest (is_going, user_id, event_id) values (false, 29, 16);
insert into public.Guest (is_going, user_id, event_id) values (false, 25, 5);
insert into public.Guest (is_going, user_id, event_id) values (true, 18, 11);
insert into public.Guest (is_going, user_id, event_id) values (true, 5, 1);
insert into public.Guest (is_going, user_id, event_id) values (true, 10, 4);
insert into public.Guest (is_going, user_id, event_id) values (true, 13, 10);
insert into public.Guest (is_going, user_id, event_id) values (false, 27, 12);
insert into public.Guest (is_going, user_id, event_id) values (true, 26, 8);
insert into public.Guest (is_going, user_id, event_id) values (false, 32, 9);
insert into public.Guest (is_going, user_id, event_id) values (false, 5, 4);
insert into public.Guest (is_going, user_id, event_id) values (true, 1, 2);
insert into public.Guest (is_going, user_id, event_id) values (false, 30, 10);
insert into public.Guest (is_going, user_id, event_id) values (true, 12, 2);
insert into public.Guest (is_going, user_id, event_id) values (false, 29, 3);
insert into public.Guest (is_going, user_id, event_id) values (false, 19, 10);
insert into public.Guest (is_going, user_id, event_id) values (false, 31, 14);
insert into public.Guest (is_going, user_id, event_id) values (true, 17, 18);
insert into public.Guest (is_going, user_id, event_id) values (true, 31, 22);
insert into public.Guest (is_going, user_id, event_id) values (true, 28, 16);
insert into public.Guest (is_going, user_id, event_id) values (true, 3, 10);
insert into public.Guest (is_going, user_id, event_id) values (true, 12, 13);
insert into public.Guest (is_going, user_id, event_id) values (false, 35, 21);
insert into public.Guest (is_going, user_id, event_id) values (true, 28, 17);
insert into public.Guest (is_going, user_id, event_id) values (true, 21, 11);
insert into public.Guest (is_going, user_id, event_id) values (true, 15, 13);
insert into public.Guest (is_going, user_id, event_id) values (true, 26, 22);
insert into public.Guest (is_going, user_id, event_id) values (true, 9, 2);
insert into public.Guest (is_going, user_id, event_id) values (false, 12, 3);
insert into public.Guest (is_going, user_id, event_id) values (false, 9, 22);
insert into public.Guest (is_going, user_id, event_id) values (false, 32, 22);
insert into public.Guest (is_going, user_id, event_id) values (false, 32, 3);
insert into public.Guest (is_going, user_id, event_id) values (false, 35, 10);
insert into public.Guest (is_going, user_id, event_id) values (false, 27, 11);
insert into public.Guest (is_going, user_id, event_id) values (false, 5, 13);
insert into public.Guest (is_going, user_id, event_id) values (true, 16, 5);
insert into public.Guest (is_going, user_id, event_id) values (false, 18, 12);
insert into public.Guest (is_going, user_id, event_id) values (false, 26, 19);
insert into public.Guest (is_going, user_id, event_id) values (true, 33, 10);
insert into public.Guest (is_going, user_id, event_id) values (true, 16, 14);
insert into public.Guest (is_going, user_id, event_id) values (true, 22, 9);
insert into public.Guest (is_going, user_id, event_id) values (false, 34, 9);
insert into public.Guest (is_going, user_id, event_id) values (true, 10, 20);
insert into public.Guest (is_going, user_id, event_id) values (true, 9, 8);
insert into public.Guest (is_going, user_id, event_id) values (true, 4, 18);
insert into public.Guest (is_going, user_id, event_id) values (false, 28, 1);
insert into public.Guest (is_going, user_id, event_id) values (true, 22, 6);
insert into public.Guest (is_going, user_id, event_id) values (false, 27, 8);
insert into public.Guest (is_going, user_id, event_id) values (false, 16, 17);
insert into public.Guest (is_going, user_id, event_id) values (false, 15, 12);
insert into public.Guest (is_going, user_id, event_id) values (true, 32, 7);
insert into public.Guest (is_going, user_id, event_id) values (false, 17, 20);
insert into public.Guest (is_going, user_id, event_id) values (false, 17, 14);
insert into public.Guest (is_going, user_id, event_id) values (false, 33, 2);
insert into public.Guest (is_going, user_id, event_id) values (false, 28, 14);
insert into public.Guest (is_going, user_id, event_id) values (true, 5, 8);
insert into public.Guest (is_going, user_id, event_id) values (true, 35, 16);
insert into public.Guest (is_going, user_id, event_id) values (false, 30, 17);
insert into public.Guest (is_going, user_id, event_id) values (true, 5, 11);
insert into public.Guest (is_going, user_id, event_id) values (true, 18, 16);
insert into public.Guest (is_going, user_id, event_id) values (true, 20, 14);
insert into public.Guest (is_going, user_id, event_id) values (true, 16, 11);
insert into public.Guest (is_going, user_id, event_id) values (true, 13, 6);
insert into public.Guest (is_going, user_id, event_id) values (true, 34, 3);
insert into public.Guest (is_going, user_id, event_id) values (false, 26, 15);
insert into public.Guest (is_going, user_id, event_id) values (true, 26, 3);
insert into public.Guest (is_going, user_id, event_id) values (true, 21, 19);
insert into public.Guest (is_going, user_id, event_id) values (true, 28, 13);
insert into public.Guest (is_going, user_id, event_id) values (true, 34, 15);
insert into public.Guest (is_going, user_id, event_id) values (true, 2, 3);
insert into public.Guest (is_going, user_id, event_id) values (false, 3, 3);
insert into public.Guest (is_going, user_id, event_id) values (true, 2, 18);
insert into public.Guest (is_going, user_id, event_id) values (true, 11, 6);
insert into public.Guest (is_going, user_id, event_id) values (true, 18, 10);
insert into public.Guest (is_going, user_id, event_id) values (true, 34, 19);
insert into public.Guest (is_going, user_id, event_id) values (true, 29, 6);
insert into public.Guest (is_going, user_id, event_id) values (true, 9, 20);
insert into public.Guest (is_going, user_id, event_id) values (true, 20, 7);
insert into public.Guest (is_going, user_id, event_id) values (true, 23, 5);
insert into public.Guest (is_going, user_id, event_id) values (true, 9, 9);
insert into public.Guest (is_going, user_id, event_id) values (true, 21, 4);
insert into public.Guest (is_going, user_id, event_id) values (false, 32, 11);
insert into public.Guest (is_going, user_id, event_id) values (false, 5, 10);
insert into public.Guest (is_going, user_id, event_id) values (true, 32, 20);
insert into public.Guest (is_going, user_id, event_id) values (true, 22, 10);
insert into public.Guest (is_going, user_id, event_id) values (false, 12, 15);
insert into public.Guest (is_going, user_id, event_id) values (true, 34, 18);
insert into public.Guest (is_going, user_id, event_id) values (false, 22, 4);
insert into public.Guest (is_going, user_id, event_id) values (false, 6, 14);
insert into public.Guest (is_going, user_id, event_id) values (true, 5, 14);
insert into public.Guest (is_going, user_id, event_id) values (false, 23, 14);
insert into public.Guest (is_going, user_id, event_id) values (false, 34, 7);
insert into public.Guest (is_going, user_id, event_id) values (false, 23, 6);
insert into public.Guest (is_going, user_id, event_id) values (true, 27, 13);
insert into public.Guest (is_going, user_id, event_id) values (false, 21, 9);
insert into public.Guest (is_going, user_id, event_id) values (true, 29, 15);
insert into public.Guest (is_going, user_id, event_id) values (false, 25, 6);
insert into public.Guest (is_going, user_id, event_id) values (true, 20, 12);
insert into public.Guest (is_going, user_id, event_id) values (true, 24, 20);
insert into public.Guest (is_going, user_id, event_id) values (false, 34, 5);
insert into public.Guest (is_going, user_id, event_id) values (true, 35, 6);
insert into public.Guest (is_going, user_id, event_id) values (false, 31, 11);
insert into public.Guest (is_going, user_id, event_id) values (false, 16, 7);
insert into public.Guest (is_going, user_id, event_id) values (false, 8, 5);
insert into public.Guest (is_going, user_id, event_id) values (true, 2, 13);
insert into public.Guest (is_going, user_id, event_id) values (true, 14, 18);
insert into public.Guest (is_going, user_id, event_id) values (false, 19, 8);
insert into public.Guest (is_going, user_id, event_id) values (true, 33, 21);
insert into public.Guest (is_going, user_id, event_id) values (true, 22, 7);
insert into public.Guest (is_going, user_id, event_id) values (false, 19, 11);
insert into public.Guest (is_going, user_id, event_id) values (false, 24, 22);
insert into public.Guest (is_going, user_id, event_id) values (true, 12, 18);
insert into public.Guest (is_going, user_id, event_id) values (false, 10, 2);
insert into public.Guest (is_going, user_id, event_id) values (true, 30, 8);
insert into public.Guest (is_going, user_id, event_id) values (false, 25, 15);
insert into public.Guest (is_going, user_id, event_id) values (true, 5, 19);
insert into public.Guest (is_going, user_id, event_id) values (true, 10, 1);
insert into public.Guest (is_going, user_id, event_id) values (true, 18, 1);
insert into public.Guest (is_going, user_id, event_id) values (false, 1, 21);
insert into public.Guest (is_going, user_id, event_id) values (true, 35, 17);
insert into public.Guest (is_going, user_id, event_id) values (true, 32, 14);
insert into public.Guest (is_going, user_id, event_id) values (false, 18, 19);
insert into public.Guest (is_going, user_id, event_id) values (false, 14, 16);
insert into public.Guest (is_going, user_id, event_id) values (true, 11, 15);
insert into public.Guest (is_going, user_id, event_id) values (false, 35, 22);
insert into public.Guest (is_going, user_id, event_id) values (false, 9, 11);
insert into public.Guest (is_going, user_id, event_id) values (true, 10, 21);
insert into public.Guest (is_going, user_id, event_id) values (true, 1, 5);
insert into public.Guest (is_going, user_id, event_id) values (false, 33, 15);
insert into public.Guest (is_going, user_id, event_id) values (false, 7, 11);

/*HOST*/
insert into public.Host (user_id, meta_event_id) values (11, 3);
insert into public.Host (user_id, meta_event_id) values (7, 3);
insert into public.Host (user_id, meta_event_id) values (27, 10);
insert into public.Host (user_id, meta_event_id) values (21, 11);
insert into public.Host (user_id, meta_event_id) values (7, 20);
insert into public.Host (user_id, meta_event_id) values (17, 20);
insert into public.Host (user_id, meta_event_id) values (6, 20);
insert into public.Host (user_id, meta_event_id) values (28, 8);
insert into public.Host (user_id, meta_event_id) values (29, 16);
insert into public.Host (user_id, meta_event_id) values (2, 12);
insert into public.Host (user_id, meta_event_id) values (3, 10);
insert into public.Host (user_id, meta_event_id) values (2, 2);
insert into public.Host (user_id, meta_event_id) values (25, 16);
insert into public.Host (user_id, meta_event_id) values (27, 20);
insert into public.Host (user_id, meta_event_id) values (22, 15);
insert into public.Host (user_id, meta_event_id) values (20, 7);
insert into public.Host (user_id, meta_event_id) values (14, 11);
insert into public.Host (user_id, meta_event_id) values (17, 8);
insert into public.Host (user_id, meta_event_id) values (29, 12);
insert into public.Host (user_id, meta_event_id) values (2, 20);

/*COMMENTS*/

insert into public.Comments (comment_id, content, photo_url, comment_date) values (1, 'turpis adipiscing lorem vitae mattis nibh ligula nec sem duis aliquam convallis nunc proin at turpis a pede posuere nonummy integer non velit donec diam neque vestibulum eget vulputate ut ultrices vel augue vestibulum ante ipsum primis in faucibus orci luctus et', 'http://epa.gov/massa/quis/augue/luctus/tincidunt/nulla.json?placerat=porta&ante=volutpat&nulla=quam&justo=pede&aliquam=lobortis&quis=ligula&turpis=sit&eget=amet&elit=eleifend&sodales=pede&scelerisque=libero&mauris=quis&sit=orci&amet=nullam&eros=molestie&suspendisse=nibh&accumsan=in&tortor=lectus&quis=pellentesque&turpis=at&sed=nulla&ante=suspendisse&vivamus=potenti&tortor=cras&duis=in&mattis=purus&egestas=eu&metus=magna&aenean=vulputate&fermentum=luctus&donec=cum', '2017-05-11 17:46:49');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (2, 'in faucibus orci luctus et ultrices posuere cubilia curae mauris viverra diam vitae quam suspendisse potenti nullam porttitor lacus at', 'http://msn.com/euismod/scelerisque/quam/turpis/adipiscing.xml?magnis=pede&dis=venenatis&parturient=non&montes=sodales&nascetur=sed&ridiculus=tincidunt&mus=eu&vivamus=felis&vestibulum=fusce&sagittis=posuere&sapien=felis&cum=sed&sociis=lacus&natoque=morbi&penatibus=sem&et=mauris&magnis=laoreet&dis=ut&parturient=rhoncus&montes=aliquet&nascetur=pulvinar&ridiculus=sed&mus=nisl&etiam=nunc&vel=rhoncus&augue=dui&vestibulum=vel&rutrum=sem&rutrum=sed&neque=sagittis&aenean=nam&auctor=congue&gravida=risus&sem=semper&praesent=porta&id=volutpat&massa=quam&id=pede&nisl=lobortis&venenatis=ligula&lacinia=sit&aenean=amet&sit=eleifend', '2016-04-02 09:40:16');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (3, 'sagittis dui vel nisl duis ac nibh fusce lacus purus aliquet at feugiat non pretium quis lectus suspendisse potenti in eleifend quam a odio in hac habitasse platea dictumst maecenas ut massa quis augue luctus tincidunt', 'https://nature.com/interdum/mauris/ullamcorper/purus/sit/amet/nulla.xml?ultrices=consequat&posuere=varius&cubilia=integer&curae=ac&donec=leo&pharetra=pellentesque', '2017-10-31 12:10:46');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (4, 'magnis dis parturient montes nascetur ridiculus mus etiam vel augue vestibulum rutrum', 'https://goo.ne.jp/lacus/morbi.js?blandit=porta&mi=volutpat&in=erat&porttitor=quisque&pede=erat&justo=eros&eu=viverra&massa=eget&donec=congue&dapibus=eget&duis=semper&at=rutrum&velit=nulla&eu=nunc&est=purus&congue=phasellus&elementum=in&in=felis&hac=donec&habitasse=semper&platea=sapien&dictumst=a&morbi=libero&vestibulum=nam&velit=dui&id=proin&pretium=leo&iaculis=odio&diam=porttitor&erat=id&fermentum=consequat&justo=in&nec=consequat&condimentum=ut&neque=nulla&sapien=sed&placerat=accumsan&ante=felis&nulla=ut&justo=at&aliquam=dolor&quis=quis&turpis=odio&eget=consequat&elit=varius&sodales=integer&scelerisque=ac&mauris=leo&sit=pellentesque&amet=ultrices&eros=mattis&suspendisse=odio&accumsan=donec&tortor=vitae&quis=nisi&turpis=nam&sed=ultrices&ante=libero&vivamus=non&tortor=mattis&duis=pulvinar&mattis=nulla&egestas=pede&metus=ullamcorper&aenean=augue&fermentum=a&donec=suscipit&ut=nulla&mauris=elit&eget=ac&massa=nulla&tempor=sed&convallis=vel&nulla=enim&neque=sit&libero=amet&convallis=nunc&eget=viverra&eleifend=dapibus&luctus=nulla&ultricies=suscipit', '2017-04-06 10:49:24');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (5, 'fermentum donec ut mauris eget massa tempor convallis nulla neque libero convallis eget eleifend luctus ultricies eu nibh quisque id justo sit amet sapien dignissim vestibulum vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae nulla dapibus dolor vel est', 'http://nydailynews.com/volutpat/erat/quisque/erat/eros/viverra.html?sed=in&magna=hac&at=habitasse&nunc=platea&commodo=dictumst&placerat=etiam&praesent=faucibus&blandit=cursus&nam=urna&nulla=ut&integer=tellus&pede=nulla&justo=ut&lacinia=erat&eget=id&tincidunt=mauris&eget=vulputate&tempus=elementum&vel=nullam&pede=varius&morbi=nulla&porttitor=facilisi&lorem=cras&id=non&ligula=velit&suspendisse=nec&ornare=nisi&consequat=vulputate&lectus=nonummy&in=maecenas&est=tincidunt&risus=lacus&auctor=at&sed=velit&tristique=vivamus&in=vel&tempus=nulla&sit=eget&amet=eros&sem=elementum&fusce=pellentesque&consequat=quisque', '2016-08-27 21:22:48');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (6, 'vivamus metus arcu adipiscing molestie hendrerit at vulputate vitae nisl aenean lectus pellentesque eget nunc donec quis orci eget orci vehicula condimentum curabitur', 'http://macromedia.com/sapien/dignissim/vestibulum/vestibulum/ante/ipsum.json?platea=porttitor&dictumst=pede&aliquam=justo&augue=eu&quam=massa&sollicitudin=donec&vitae=dapibus&consectetuer=duis&eget=at&rutrum=velit&at=eu&lorem=est&integer=congue&tincidunt=elementum&ante=in&vel=hac&ipsum=habitasse&praesent=platea&blandit=dictumst&lacinia=morbi&erat=vestibulum&vestibulum=velit&sed=id&magna=pretium&at=iaculis&nunc=diam&commodo=erat&placerat=fermentum&praesent=justo&blandit=nec&nam=condimentum&nulla=neque&integer=sapien&pede=placerat&justo=ante&lacinia=nulla&eget=justo&tincidunt=aliquam&eget=quis&tempus=turpis&vel=eget&pede=elit&morbi=sodales&porttitor=scelerisque&lorem=mauris&id=sit&ligula=amet&suspendisse=eros&ornare=suspendisse&consequat=accumsan&lectus=tortor&in=quis&est=turpis&risus=sed&auctor=ante&sed=vivamus&tristique=tortor&in=duis&tempus=mattis&sit=egestas&amet=metus&sem=aenean&fusce=fermentum&consequat=donec&nulla=ut&nisl=mauris&nunc=eget&nisl=massa&duis=tempor&bibendum=convallis&felis=nulla&sed=neque&interdum=libero&venenatis=convallis&turpis=eget&enim=eleifend&blandit=luctus&mi=ultricies&in=eu&porttitor=nibh&pede=quisque&justo=id', '2017-06-20 01:11:50');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (7, 'et ultrices posuere cubilia curae nulla dapibus dolor vel est donec odio justo sollicitudin ut suscipit a feugiat et eros vestibulum ac est lacinia nisi venenatis tristique fusce congue diam id ornare imperdiet sapien', 'https://zdnet.com/praesent/blandit/nam/nulla/integer/pede/justo.aspx?augue=lacinia&luctus=sapien&tincidunt=quis&nulla=libero&mollis=nullam&molestie=sit&lorem=amet&quisque=turpis&ut=elementum&erat=ligula&curabitur=vehicula&gravida=consequat&nisi=morbi&at=a&nibh=ipsum&in=integer&hac=a&habitasse=nibh&platea=in&dictumst=quis&aliquam=justo&augue=maecenas&quam=rhoncus&sollicitudin=aliquam&vitae=lacus&consectetuer=morbi&eget=quis&rutrum=tortor&at=id&lorem=nulla&integer=ultrices&tincidunt=aliquet&ante=maecenas&vel=leo&ipsum=odio&praesent=condimentum&blandit=id&lacinia=luctus&erat=nec&vestibulum=molestie&sed=sed&magna=justo&at=pellentesque&nunc=viverra&commodo=pede&placerat=ac&praesent=diam&blandit=cras&nam=pellentesque&nulla=volutpat&integer=dui&pede=maecenas&justo=tristique&lacinia=est&eget=et&tincidunt=tempus&eget=semper&tempus=est&vel=quam&pede=pharetra&morbi=magna&porttitor=ac&lorem=consequat&id=metus&ligula=sapien&suspendisse=ut&ornare=nunc&consequat=vestibulum&lectus=ante&in=ipsum&est=primis&risus=in&auctor=faucibus&sed=orci&tristique=luctus&in=et', '2016-04-15 23:25:15');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (8, 'mattis egestas metus aenean fermentum donec ut mauris eget massa tempor convallis nulla neque libero convallis eget eleifend luctus ultricies eu nibh quisque id justo sit amet sapien dignissim vestibulum', 'http://google.es/penatibus.jsp?morbi=mus&odio=vivamus&odio=vestibulum&elementum=sagittis&eu=sapien&interdum=cum&eu=sociis&tincidunt=natoque&in=penatibus&leo=et&maecenas=magnis&pulvinar=dis&lobortis=parturient&est=montes&phasellus=nascetur&sit=ridiculus&amet=mus&erat=etiam&nulla=vel&tempus=augue&vivamus=vestibulum&in=rutrum&felis=rutrum&eu=neque&sapien=aenean&cursus=auctor&vestibulum=gravida&proin=sem&eu=praesent&mi=id&nulla=massa&ac=id&enim=nisl&in=venenatis&tempor=lacinia&turpis=aenean&nec=sit&euismod=amet&scelerisque=justo&quam=morbi&turpis=ut&adipiscing=odio&lorem=cras&vitae=mi&mattis=pede&nibh=malesuada&ligula=in&nec=imperdiet&sem=et&duis=commodo&aliquam=vulputate&convallis=justo&nunc=in&proin=blandit&at=ultrices&turpis=enim&a=lorem&pede=ipsum&posuere=dolor&nonummy=sit&integer=amet&non=consectetuer&velit=adipiscing&donec=elit&diam=proin&neque=interdum&vestibulum=mauris&eget=non&vulputate=ligula&ut=pellentesque&ultrices=ultrices&vel=phasellus&augue=id&vestibulum=sapien&ante=in&ipsum=sapien&primis=iaculis&in=congue&faucibus=vivamus&orci=metus&luctus=arcu&et=adipiscing&ultrices=molestie&posuere=hendrerit&cubilia=at&curae=vulputate&donec=vitae&pharetra=nisl&magna=aenean&vestibulum=lectus', '2017-04-15 18:40:07');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (9, 'sit amet turpis elementum ligula vehicula consequat morbi a ipsum integer a nibh in quis justo maecenas rhoncus aliquam lacus morbi quis tortor id nulla ultrices aliquet maecenas leo odio condimentum', 'https://twitter.com/consequat/dui.aspx?mi=maecenas&nulla=rhoncus&ac=aliquam&enim=lacus&in=morbi&tempor=quis&turpis=tortor&nec=id&euismod=nulla&scelerisque=ultrices&quam=aliquet&turpis=maecenas&adipiscing=leo&lorem=odio&vitae=condimentum&mattis=id&nibh=luctus&ligula=nec&nec=molestie&sem=sed&duis=justo&aliquam=pellentesque&convallis=viverra&nunc=pede&proin=ac&at=diam&turpis=cras&a=pellentesque&pede=volutpat&posuere=dui&nonummy=maecenas&integer=tristique&non=est&velit=et&donec=tempus&diam=semper&neque=est&vestibulum=quam&eget=pharetra&vulputate=magna', '2018-02-26 07:06:40');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (10, 'mauris eget massa tempor convallis nulla neque libero convallis eget eleifend luctus ultricies eu nibh quisque id justo sit amet sapien dignissim vestibulum vestibulum ante ipsum primis in faucibus orci luctus et', 'http://multiply.com/erat/eros/viverra.aspx?in=ut&quam=at&fringilla=dolor&rhoncus=quis&mauris=odio&enim=consequat&leo=varius&rhoncus=integer&sed=ac&vestibulum=leo&sit=pellentesque&amet=ultrices&cursus=mattis&id=odio&turpis=donec&integer=vitae&aliquet=nisi&massa=nam&id=ultrices&lobortis=libero&convallis=non&tortor=mattis&risus=pulvinar&dapibus=nulla&augue=pede&vel=ullamcorper&accumsan=augue&tellus=a&nisi=suscipit&eu=nulla&orci=elit&mauris=ac&lacinia=nulla&sapien=sed&quis=vel&libero=enim&nullam=sit&sit=amet&amet=nunc&turpis=viverra&elementum=dapibus&ligula=nulla&vehicula=suscipit&consequat=ligula', '2016-09-25 02:56:38');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (11, 'ut suscipit a feugiat et eros vestibulum ac est lacinia nisi venenatis tristique fusce congue diam id ornare imperdiet sapien urna pretium nisl ut volutpat sapien arcu sed augue aliquam erat volutpat', 'https://homestead.com/enim/lorem/ipsum/dolor/sit.js?ligula=quam&sit=sollicitudin&amet=vitae&eleifend=consectetuer&pede=eget&libero=rutrum&quis=at&orci=lorem&nullam=integer&molestie=tincidunt&nibh=ante&in=vel&lectus=ipsum&pellentesque=praesent&at=blandit&nulla=lacinia&suspendisse=erat&potenti=vestibulum&cras=sed&in=magna&purus=at&eu=nunc&magna=commodo&vulputate=placerat&luctus=praesent&cum=blandit&sociis=nam&natoque=nulla&penatibus=integer&et=pede&magnis=justo&dis=lacinia&parturient=eget&montes=tincidunt&nascetur=eget&ridiculus=tempus&mus=vel&vivamus=pede&vestibulum=morbi&sagittis=porttitor&sapien=lorem&cum=id&sociis=ligula', '2017-04-28 05:02:22');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (12, 'quam sollicitudin vitae consectetuer eget rutrum at lorem integer tincidunt ante vel ipsum praesent blandit lacinia erat vestibulum sed magna at nunc commodo placerat praesent blandit nam nulla integer pede justo lacinia eget tincidunt eget tempus vel pede morbi porttitor lorem id ligula suspendisse ornare consequat lectus in est', 'http://usnews.com/cursus/vestibulum/proin/eu/mi/nulla/ac.aspx?dui=lacus&vel=at&sem=turpis&sed=donec&sagittis=posuere&nam=metus&congue=vitae&risus=ipsum&semper=aliquam&porta=non&volutpat=mauris&quam=morbi&pede=non&lobortis=lectus&ligula=aliquam&sit=sit&amet=amet&eleifend=diam&pede=in&libero=magna&quis=bibendum&orci=imperdiet&nullam=nullam&molestie=orci&nibh=pede&in=venenatis&lectus=non&pellentesque=sodales&at=sed&nulla=tincidunt&suspendisse=eu&potenti=felis&cras=fusce&in=posuere&purus=felis&eu=sed&magna=lacus&vulputate=morbi&luctus=sem', '2018-05-16 07:10:57');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (13, 'primis in faucibus orci luctus et ultrices posuere cubilia curae duis faucibus accumsan odio curabitur convallis duis consequat dui nec nisi volutpat eleifend donec ut dolor', 'https://twitpic.com/aliquet/pulvinar/sed/nisl/nunc.js?tincidunt=duis&eget=aliquam&tempus=convallis&vel=nunc&pede=proin&morbi=at&porttitor=turpis&lorem=a&id=pede&ligula=posuere&suspendisse=nonummy&ornare=integer&consequat=non&lectus=velit&in=donec&est=diam&risus=neque&auctor=vestibulum&sed=eget&tristique=vulputate&in=ut&tempus=ultrices&sit=vel&amet=augue&sem=vestibulum&fusce=ante&consequat=ipsum&nulla=primis&nisl=in&nunc=faucibus&nisl=orci&duis=luctus&bibendum=et&felis=ultrices&sed=posuere&interdum=cubilia&venenatis=curae&turpis=donec&enim=pharetra&blandit=magna&mi=vestibulum&in=aliquet&porttitor=ultrices&pede=erat&justo=tortor&eu=sollicitudin&massa=mi&donec=sit&dapibus=amet&duis=lobortis&at=sapien&velit=sapien&eu=non&est=mi&congue=integer&elementum=ac&in=neque&hac=duis&habitasse=bibendum&platea=morbi&dictumst=non&morbi=quam&vestibulum=nec&velit=dui&id=luctus&pretium=rutrum&iaculis=nulla&diam=tellus&erat=in&fermentum=sagittis&justo=dui&nec=vel&condimentum=nisl&neque=duis&sapien=ac&placerat=nibh', '2017-05-12 15:30:02');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (14, 'phasellus id sapien in sapien iaculis congue vivamus metus arcu adipiscing molestie hendrerit at vulputate vitae nisl aenean lectus pellentesque eget nunc donec quis orci eget orci vehicula condimentum curabitur in libero ut massa volutpat convallis morbi odio odio elementum eu', 'https://reverbnation.com/elementum/nullam/varius/nulla/facilisi/cras.png?quam=nam&pede=congue&lobortis=risus&ligula=semper&sit=porta&amet=volutpat&eleifend=quam&pede=pede&libero=lobortis&quis=ligula&orci=sit&nullam=amet&molestie=eleifend&nibh=pede&in=libero&lectus=quis&pellentesque=orci&at=nullam&nulla=molestie&suspendisse=nibh&potenti=in&cras=lectus&in=pellentesque&purus=at&eu=nulla&magna=suspendisse&vulputate=potenti&luctus=cras&cum=in&sociis=purus&natoque=eu&penatibus=magna&et=vulputate&magnis=luctus&dis=cum&parturient=sociis&montes=natoque&nascetur=penatibus&ridiculus=et&mus=magnis&vivamus=dis&vestibulum=parturient&sagittis=montes&sapien=nascetur&cum=ridiculus&sociis=mus&natoque=vivamus&penatibus=vestibulum&et=sagittis&magnis=sapien&dis=cum&parturient=sociis&montes=natoque&nascetur=penatibus&ridiculus=et&mus=magnis&etiam=dis&vel=parturient&augue=montes', '2017-09-22 03:20:33');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (15, 'dictumst morbi vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum neque sapien placerat ante nulla justo aliquam quis turpis eget elit sodales scelerisque mauris sit amet eros suspendisse accumsan tortor quis turpis sed ante vivamus tortor duis mattis egestas', 'http://webeden.co.uk/justo.jpg?ridiculus=nulla&mus=tempus&etiam=vivamus&vel=in&augue=felis&vestibulum=eu&rutrum=sapien&rutrum=cursus&neque=vestibulum&aenean=proin&auctor=eu&gravida=mi&sem=nulla&praesent=ac&id=enim&massa=in&id=tempor&nisl=turpis&venenatis=nec&lacinia=euismod&aenean=scelerisque&sit=quam&amet=turpis&justo=adipiscing&morbi=lorem&ut=vitae&odio=mattis&cras=nibh&mi=ligula&pede=nec&malesuada=sem&in=duis&imperdiet=aliquam&et=convallis&commodo=nunc&vulputate=proin&justo=at&in=turpis&blandit=a&ultrices=pede&enim=posuere&lorem=nonummy&ipsum=integer&dolor=non&sit=velit&amet=donec&consectetuer=diam&adipiscing=neque&elit=vestibulum&proin=eget&interdum=vulputate&mauris=ut&non=ultrices&ligula=vel&pellentesque=augue&ultrices=vestibulum&phasellus=ante&id=ipsum&sapien=primis&in=in&sapien=faucibus&iaculis=orci&congue=luctus&vivamus=et&metus=ultrices&arcu=posuere&adipiscing=cubilia&molestie=curae&hendrerit=donec&at=pharetra&vulputate=magna&vitae=vestibulum&nisl=aliquet&aenean=ultrices&lectus=erat&pellentesque=tortor&eget=sollicitudin&nunc=mi&donec=sit&quis=amet&orci=lobortis&eget=sapien&orci=sapien&vehicula=non', '2017-11-26 01:05:50');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (16, 'tristique in tempus sit amet sem fusce consequat nulla nisl nunc nisl duis bibendum felis sed', 'https://cbslocal.com/proin/interdum/mauris/non/ligula.xml?eu=ut', '2016-11-19 05:13:41');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (17, 'ac enim in tempor turpis nec euismod scelerisque quam turpis adipiscing lorem vitae mattis nibh ligula nec sem duis aliquam convallis nunc proin at turpis a pede posuere nonummy integer non velit donec diam neque vestibulum eget vulputate ut ultrices vel augue vestibulum ante', 'https://about.me/penatibus/et/magnis.html?dolor=ante&sit=vestibulum&amet=ante&consectetuer=ipsum&adipiscing=primis&elit=in&proin=faucibus&interdum=orci&mauris=luctus&non=et&ligula=ultrices&pellentesque=posuere&ultrices=cubilia&phasellus=curae&id=duis&sapien=faucibus&in=accumsan&sapien=odio&iaculis=curabitur&congue=convallis&vivamus=duis&metus=consequat&arcu=dui&adipiscing=nec&molestie=nisi&hendrerit=volutpat&at=eleifend&vulputate=donec&vitae=ut&nisl=dolor&aenean=morbi&lectus=vel&pellentesque=lectus&eget=in&nunc=quam&donec=fringilla&quis=rhoncus&orci=mauris&eget=enim&orci=leo&vehicula=rhoncus&condimentum=sed&curabitur=vestibulum&in=sit&libero=amet&ut=cursus&massa=id&volutpat=turpis&convallis=integer&morbi=aliquet&odio=massa&odio=id', '2016-11-20 04:17:09');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (18, 'aenean lectus pellentesque eget nunc donec quis orci eget orci vehicula condimentum curabitur in libero ut massa volutpat convallis morbi odio odio', 'http://jugem.jp/tempus/vivamus.jpg?cursus=mauris&urna=sit&ut=amet&tellus=eros&nulla=suspendisse&ut=accumsan&erat=tortor&id=quis&mauris=turpis&vulputate=sed&elementum=ante&nullam=vivamus&varius=tortor&nulla=duis&facilisi=mattis&cras=egestas&non=metus&velit=aenean&nec=fermentum&nisi=donec&vulputate=ut&nonummy=mauris&maecenas=eget&tincidunt=massa&lacus=tempor&at=convallis&velit=nulla&vivamus=neque&vel=libero&nulla=convallis&eget=eget&eros=eleifend&elementum=luctus&pellentesque=ultricies&quisque=eu&porta=nibh&volutpat=quisque&erat=id&quisque=justo&erat=sit&eros=amet&viverra=sapien&eget=dignissim&congue=vestibulum&eget=vestibulum&semper=ante&rutrum=ipsum&nulla=primis&nunc=in&purus=faucibus&phasellus=orci&in=luctus&felis=et&donec=ultrices&semper=posuere&sapien=cubilia&a=curae&libero=nulla&nam=dapibus&dui=dolor&proin=vel&leo=est&odio=donec&porttitor=odio&id=justo&consequat=sollicitudin&in=ut&consequat=suscipit&ut=a&nulla=feugiat', '2017-04-19 22:23:32');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (19, 'congue elementum in hac habitasse platea dictumst morbi vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum neque sapien placerat ante nulla justo aliquam quis', 'https://dot.gov/potenti/in/eleifend/quam/a/odio.json?sapien=vulputate&in=elementum&sapien=nullam&iaculis=varius&congue=nulla&vivamus=facilisi&metus=cras&arcu=non&adipiscing=velit&molestie=nec&hendrerit=nisi&at=vulputate&vulputate=nonummy&vitae=maecenas&nisl=tincidunt&aenean=lacus&lectus=at&pellentesque=velit&eget=vivamus', '2017-06-24 18:56:20');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (20, 'nunc rhoncus dui vel sem sed sagittis nam congue risus semper porta volutpat quam pede lobortis ligula sit amet eleifend pede libero quis orci nullam molestie nibh in lectus pellentesque at nulla suspendisse potenti cras in purus eu magna vulputate luctus cum sociis natoque penatibus et magnis dis', 'https://arizona.edu/erat/volutpat/in.xml?platea=quis&dictumst=augue&etiam=luctus&faucibus=tincidunt&cursus=nulla&urna=mollis&ut=molestie&tellus=lorem&nulla=quisque&ut=ut&erat=erat&id=curabitur&mauris=gravida&vulputate=nisi&elementum=at&nullam=nibh&varius=in&nulla=hac', '2017-08-17 09:09:26');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (21, 'vestibulum sagittis sapien cum sociis natoque penatibus et magnis dis parturient montes nascetur ridiculus mus etiam vel augue vestibulum rutrum rutrum neque aenean auctor gravida sem praesent id massa id nisl venenatis lacinia aenean sit amet justo morbi ut', 'http://nba.com/sed/accumsan/felis/ut/at.aspx?odio=nisl&odio=ut&elementum=volutpat&eu=sapien&interdum=arcu&eu=sed&tincidunt=augue&in=aliquam&leo=erat&maecenas=volutpat&pulvinar=in&lobortis=congue&est=etiam&phasellus=justo&sit=etiam&amet=pretium&erat=iaculis&nulla=justo&tempus=in&vivamus=hac&in=habitasse&felis=platea&eu=dictumst&sapien=etiam&cursus=faucibus&vestibulum=cursus&proin=urna&eu=ut&mi=tellus&nulla=nulla&ac=ut&enim=erat&in=id&tempor=mauris&turpis=vulputate&nec=elementum&euismod=nullam&scelerisque=varius&quam=nulla&turpis=facilisi&adipiscing=cras&lorem=non&vitae=velit&mattis=nec&nibh=nisi&ligula=vulputate&nec=nonummy&sem=maecenas&duis=tincidunt&aliquam=lacus&convallis=at&nunc=velit&proin=vivamus&at=vel&turpis=nulla&a=eget&pede=eros&posuere=elementum&nonummy=pellentesque&integer=quisque&non=porta&velit=volutpat&donec=erat&diam=quisque&neque=erat&vestibulum=eros&eget=viverra&vulputate=eget&ut=congue&ultrices=eget&vel=semper&augue=rutrum&vestibulum=nulla&ante=nunc&ipsum=purus&primis=phasellus&in=in&faucibus=felis', '2018-01-18 19:46:40');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (22, 'nibh in hac habitasse platea dictumst aliquam augue quam sollicitudin vitae consectetuer eget rutrum at lorem integer tincidunt ante vel ipsum praesent blandit', 'http://last.fm/eu/tincidunt/in/leo/maecenas/pulvinar.png?leo=in&pellentesque=hac&ultrices=habitasse&mattis=platea&odio=dictumst&donec=morbi&vitae=vestibulum&nisi=velit&nam=id&ultrices=pretium&libero=iaculis&non=diam&mattis=erat&pulvinar=fermentum&nulla=justo&pede=nec&ullamcorper=condimentum&augue=neque&a=sapien&suscipit=placerat&nulla=ante&elit=nulla&ac=justo&nulla=aliquam&sed=quis&vel=turpis&enim=eget&sit=elit&amet=sodales&nunc=scelerisque&viverra=mauris&dapibus=sit&nulla=amet&suscipit=eros&ligula=suspendisse&in=accumsan&lacus=tortor&curabitur=quis&at=turpis&ipsum=sed&ac=ante&tellus=vivamus&semper=tortor&interdum=duis&mauris=mattis&ullamcorper=egestas&purus=metus&sit=aenean&amet=fermentum&nulla=donec&quisque=ut&arcu=mauris&libero=eget&rutrum=massa', '2018-05-31 07:55:43');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (23, 'vestibulum quam sapien varius ut blandit non interdum in ante vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae duis faucibus accumsan odio curabitur convallis duis consequat dui nec nisi volutpat eleifend donec ut', 'https://ezinearticles.com/congue/etiam/justo/etiam.aspx?nibh=nisi&ligula=eu&nec=orci&sem=mauris&duis=lacinia&aliquam=sapien&convallis=quis&nunc=libero&proin=nullam&at=sit&turpis=amet&a=turpis&pede=elementum&posuere=ligula&nonummy=vehicula&integer=consequat&non=morbi&velit=a&donec=ipsum&diam=integer&neque=a&vestibulum=nibh&eget=in&vulputate=quis&ut=justo&ultrices=maecenas&vel=rhoncus&augue=aliquam&vestibulum=lacus&ante=morbi&ipsum=quis&primis=tortor&in=id&faucibus=nulla&orci=ultrices&luctus=aliquet&et=maecenas&ultrices=leo&posuere=odio&cubilia=condimentum', '2017-09-20 05:01:27');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (24, 'pharetra magna ac consequat metus sapien ut nunc vestibulum ante ipsum primis', 'http://dagondesign.com/quisque/erat/eros/viverra/eget.aspx?in=duis&lectus=ac&pellentesque=nibh&at=fusce&nulla=lacus&suspendisse=purus&potenti=aliquet&cras=at&in=feugiat&purus=non&eu=pretium&magna=quis&vulputate=lectus&luctus=suspendisse&cum=potenti&sociis=in&natoque=eleifend&penatibus=quam&et=a&magnis=odio&dis=in&parturient=hac&montes=habitasse&nascetur=platea&ridiculus=dictumst&mus=maecenas&vivamus=ut&vestibulum=massa&sagittis=quis&sapien=augue&cum=luctus&sociis=tincidunt&natoque=nulla&penatibus=mollis&et=molestie&magnis=lorem&dis=quisque&parturient=ut&montes=erat&nascetur=curabitur&ridiculus=gravida&mus=nisi&etiam=at&vel=nibh&augue=in&vestibulum=hac&rutrum=habitasse&rutrum=platea&neque=dictumst&aenean=aliquam&auctor=augue&gravida=quam&sem=sollicitudin&praesent=vitae&id=consectetuer&massa=eget&id=rutrum&nisl=at&venenatis=lorem&lacinia=integer&aenean=tincidunt&sit=ante&amet=vel&justo=ipsum&morbi=praesent', '2016-12-11 12:58:29');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (25, 'nulla pede ullamcorper augue a suscipit nulla elit ac nulla sed vel enim sit amet nunc viverra dapibus nulla suscipit ligula in lacus curabitur at ipsum ac tellus semper interdum mauris ullamcorper purus sit amet nulla quisque arcu libero', 'http://behance.net/donec/pharetra/magna.xml?fusce=nisi&congue=venenatis&diam=tristique&id=fusce&ornare=congue&imperdiet=diam&sapien=id&urna=ornare&pretium=imperdiet&nisl=sapien&ut=urna&volutpat=pretium&sapien=nisl&arcu=ut&sed=volutpat&augue=sapien&aliquam=arcu&erat=sed&volutpat=augue&in=aliquam&congue=erat', '2017-12-29 01:09:59');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (26, 'est congue elementum in hac habitasse platea dictumst morbi vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum neque sapien placerat ante nulla justo aliquam quis turpis eget elit sodales scelerisque mauris sit amet eros suspendisse accumsan tortor quis', 'https://oracle.com/sed/augue/aliquam/erat.jsp?orci=eget&luctus=nunc&et=donec&ultrices=quis&posuere=orci&cubilia=eget&curae=orci&mauris=vehicula&viverra=condimentum&diam=curabitur&vitae=in&quam=libero&suspendisse=ut&potenti=massa&nullam=volutpat&porttitor=convallis&lacus=morbi&at=odio&turpis=odio&donec=elementum&posuere=eu&metus=interdum&vitae=eu&ipsum=tincidunt&aliquam=in&non=leo&mauris=maecenas&morbi=pulvinar&non=lobortis&lectus=est&aliquam=phasellus&sit=sit&amet=amet&diam=erat&in=nulla&magna=tempus&bibendum=vivamus&imperdiet=in&nullam=felis&orci=eu&pede=sapien&venenatis=cursus&non=vestibulum&sodales=proin&sed=eu&tincidunt=mi&eu=nulla&felis=ac&fusce=enim&posuere=in&felis=tempor&sed=turpis&lacus=nec&morbi=euismod&sem=scelerisque&mauris=quam&laoreet=turpis&ut=adipiscing&rhoncus=lorem&aliquet=vitae&pulvinar=mattis&sed=nibh&nisl=ligula', '2017-02-23 21:59:13');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (27, 'proin interdum mauris non ligula pellentesque ultrices phasellus id sapien in sapien iaculis congue vivamus metus arcu adipiscing molestie hendrerit at vulputate vitae nisl aenean lectus pellentesque eget nunc donec quis orci eget orci vehicula condimentum curabitur in', 'http://themeforest.net/erat/id/mauris/vulputate.xml?nulla=porttitor&eget=lorem&eros=id&elementum=ligula&pellentesque=suspendisse&quisque=ornare&porta=consequat&volutpat=lectus&erat=in&quisque=est&erat=risus&eros=auctor&viverra=sed&eget=tristique&congue=in&eget=tempus&semper=sit&rutrum=amet&nulla=sem&nunc=fusce&purus=consequat&phasellus=nulla&in=nisl&felis=nunc&donec=nisl&semper=duis&sapien=bibendum&a=felis&libero=sed&nam=interdum&dui=venenatis&proin=turpis&leo=enim&odio=blandit&porttitor=mi&id=in&consequat=porttitor&in=pede&consequat=justo&ut=eu&nulla=massa&sed=donec&accumsan=dapibus&felis=duis&ut=at&at=velit&dolor=eu&quis=est&odio=congue&consequat=elementum&varius=in&integer=hac&ac=habitasse&leo=platea&pellentesque=dictumst&ultrices=morbi&mattis=vestibulum&odio=velit&donec=id&vitae=pretium&nisi=iaculis&nam=diam&ultrices=erat&libero=fermentum&non=justo&mattis=nec&pulvinar=condimentum&nulla=neque&pede=sapien&ullamcorper=placerat&augue=ante&a=nulla&suscipit=justo&nulla=aliquam&elit=quis&ac=turpis&nulla=eget&sed=elit&vel=sodales&enim=scelerisque&sit=mauris', '2017-07-21 13:26:49');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (28, 'velit eu est congue elementum in hac habitasse platea dictumst morbi vestibulum velit id pretium iaculis diam erat fermentum', 'https://networkadvertising.org/nunc/nisl/duis/bibendum/felis/sed/interdum.jpg?posuere=etiam&cubilia=pretium&curae=iaculis&donec=justo&pharetra=in&magna=hac&vestibulum=habitasse&aliquet=platea&ultrices=dictumst&erat=etiam&tortor=faucibus&sollicitudin=cursus&mi=urna&sit=ut&amet=tellus&lobortis=nulla&sapien=ut&sapien=erat&non=id&mi=mauris&integer=vulputate&ac=elementum&neque=nullam&duis=varius&bibendum=nulla&morbi=facilisi&non=cras&quam=non&nec=velit&dui=nec&luctus=nisi&rutrum=vulputate&nulla=nonummy&tellus=maecenas&in=tincidunt&sagittis=lacus&dui=at&vel=velit&nisl=vivamus&duis=vel&ac=nulla&nibh=eget&fusce=eros&lacus=elementum&purus=pellentesque&aliquet=quisque&at=porta&feugiat=volutpat&non=erat&pretium=quisque&quis=erat&lectus=eros&suspendisse=viverra&potenti=eget&in=congue&eleifend=eget&quam=semper&a=rutrum&odio=nulla&in=nunc&hac=purus&habitasse=phasellus&platea=in&dictumst=felis&maecenas=donec&ut=semper&massa=sapien&quis=a&augue=libero&luctus=nam&tincidunt=dui&nulla=proin&mollis=leo&molestie=odio&lorem=porttitor&quisque=id&ut=consequat&erat=in&curabitur=consequat', '2017-01-26 09:31:53');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (29, 'sit amet consectetuer adipiscing elit proin interdum mauris non ligula pellentesque ultrices phasellus id sapien in sapien iaculis congue vivamus metus arcu adipiscing molestie hendrerit at vulputate vitae nisl aenean lectus pellentesque eget nunc donec quis orci eget orci vehicula condimentum', 'http://nbcnews.com/lorem/vitae/mattis/nibh/ligula/nec/sem.html?erat=integer&eros=ac&viverra=neque&eget=duis&congue=bibendum&eget=morbi&semper=non&rutrum=quam&nulla=nec&nunc=dui&purus=luctus&phasellus=rutrum&in=nulla&felis=tellus&donec=in&semper=sagittis&sapien=dui&a=vel&libero=nisl&nam=duis&dui=ac&proin=nibh&leo=fusce&odio=lacus&porttitor=purus&id=aliquet&consequat=at&in=feugiat&consequat=non&ut=pretium&nulla=quis&sed=lectus&accumsan=suspendisse&felis=potenti&ut=in&at=eleifend&dolor=quam&quis=a&odio=odio&consequat=in&varius=hac&integer=habitasse&ac=platea&leo=dictumst&pellentesque=maecenas&ultrices=ut&mattis=massa&odio=quis&donec=augue&vitae=luctus&nisi=tincidunt&nam=nulla&ultrices=mollis&libero=molestie&non=lorem&mattis=quisque', '2016-10-24 12:00:05');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (30, 'aliquam augue quam sollicitudin vitae consectetuer eget rutrum at lorem integer tincidunt', 'http://ezinearticles.com/platea/dictumst.js?curabitur=consectetuer&convallis=adipiscing&duis=elit&consequat=proin&dui=risus&nec=praesent&nisi=lectus&volutpat=vestibulum&eleifend=quam&donec=sapien&ut=varius&dolor=ut&morbi=blandit&vel=non&lectus=interdum&in=in&quam=ante&fringilla=vestibulum&rhoncus=ante&mauris=ipsum&enim=primis&leo=in&rhoncus=faucibus&sed=orci&vestibulum=luctus&sit=et&amet=ultrices&cursus=posuere&id=cubilia&turpis=curae&integer=duis&aliquet=faucibus&massa=accumsan&id=odio&lobortis=curabitur&convallis=convallis&tortor=duis&risus=consequat&dapibus=dui&augue=nec&vel=nisi&accumsan=volutpat&tellus=eleifend&nisi=donec&eu=ut&orci=dolor&mauris=morbi&lacinia=vel&sapien=lectus&quis=in&libero=quam&nullam=fringilla&sit=rhoncus&amet=mauris&turpis=enim&elementum=leo&ligula=rhoncus&vehicula=sed&consequat=vestibulum&morbi=sit&a=amet&ipsum=cursus&integer=id&a=turpis&nibh=integer&in=aliquet&quis=massa&justo=id&maecenas=lobortis&rhoncus=convallis&aliquam=tortor&lacus=risus', '2017-09-27 10:01:45');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (31, 'tristique in tempus sit amet sem fusce consequat nulla nisl nunc nisl duis bibendum felis sed interdum venenatis turpis enim blandit mi in porttitor', 'http://t-online.de/proin.html?congue=in&eget=blandit&semper=ultrices&rutrum=enim&nulla=lorem&nunc=ipsum&purus=dolor&phasellus=sit&in=amet&felis=consectetuer&donec=adipiscing&semper=elit&sapien=proin&a=interdum&libero=mauris&nam=non&dui=ligula&proin=pellentesque&leo=ultrices&odio=phasellus&porttitor=id&id=sapien&consequat=in&in=sapien&consequat=iaculis&ut=congue&nulla=vivamus&sed=metus&accumsan=arcu&felis=adipiscing&ut=molestie&at=hendrerit&dolor=at&quis=vulputate&odio=vitae&consequat=nisl&varius=aenean&integer=lectus&ac=pellentesque&leo=eget&pellentesque=nunc&ultrices=donec&mattis=quis&odio=orci&donec=eget&vitae=orci&nisi=vehicula&nam=condimentum&ultrices=curabitur&libero=in&non=libero&mattis=ut&pulvinar=massa&nulla=volutpat&pede=convallis&ullamcorper=morbi&augue=odio&a=odio&suscipit=elementum&nulla=eu&elit=interdum&ac=eu&nulla=tincidunt&sed=in&vel=leo&enim=maecenas&sit=pulvinar&amet=lobortis&nunc=est&viverra=phasellus&dapibus=sit&nulla=amet&suscipit=erat&ligula=nulla&in=tempus&lacus=vivamus&curabitur=in&at=felis&ipsum=eu&ac=sapien&tellus=cursus&semper=vestibulum', '2017-11-23 19:44:23');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (32, 'lectus aliquam sit amet diam in magna bibendum imperdiet nullam orci pede venenatis', 'https://exblog.jp/penatibus.png?lectus=volutpat&in=dui&quam=maecenas&fringilla=tristique&rhoncus=est&mauris=et&enim=tempus&leo=semper&rhoncus=est&sed=quam&vestibulum=pharetra&sit=magna&amet=ac&cursus=consequat&id=metus&turpis=sapien&integer=ut&aliquet=nunc&massa=vestibulum&id=ante&lobortis=ipsum&convallis=primis&tortor=in&risus=faucibus&dapibus=orci&augue=luctus&vel=et&accumsan=ultrices&tellus=posuere&nisi=cubilia&eu=curae&orci=mauris&mauris=viverra&lacinia=diam&sapien=vitae&quis=quam&libero=suspendisse&nullam=potenti&sit=nullam&amet=porttitor&turpis=lacus&elementum=at&ligula=turpis&vehicula=donec&consequat=posuere&morbi=metus', '2016-06-26 18:06:33');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (33, 'consequat in consequat ut nulla sed accumsan felis ut at dolor quis odio consequat varius integer ac leo pellentesque ultrices mattis odio donec vitae nisi nam ultrices libero non mattis pulvinar nulla pede ullamcorper augue a suscipit nulla elit ac nulla sed vel enim', 'http://bandcamp.com/vulputate.html?sapien=semper&placerat=est&ante=quam&nulla=pharetra&justo=magna&aliquam=ac&quis=consequat&turpis=metus&eget=sapien&elit=ut&sodales=nunc&scelerisque=vestibulum&mauris=ante&sit=ipsum&amet=primis&eros=in&suspendisse=faucibus&accumsan=orci&tortor=luctus&quis=et&turpis=ultrices&sed=posuere&ante=cubilia&vivamus=curae&tortor=mauris&duis=viverra&mattis=diam&egestas=vitae&metus=quam&aenean=suspendisse&fermentum=potenti&donec=nullam&ut=porttitor&mauris=lacus&eget=at&massa=turpis&tempor=donec&convallis=posuere&nulla=metus&neque=vitae&libero=ipsum&convallis=aliquam&eget=non&eleifend=mauris&luctus=morbi&ultricies=non&eu=lectus&nibh=aliquam&quisque=sit&id=amet&justo=diam&sit=in&amet=magna&sapien=bibendum&dignissim=imperdiet&vestibulum=nullam&vestibulum=orci&ante=pede&ipsum=venenatis&primis=non&in=sodales&faucibus=sed&orci=tincidunt&luctus=eu&et=felis&ultrices=fusce&posuere=posuere&cubilia=felis&curae=sed&nulla=lacus&dapibus=morbi&dolor=sem&vel=mauris&est=laoreet&donec=ut&odio=rhoncus&justo=aliquet&sollicitudin=pulvinar&ut=sed&suscipit=nisl&a=nunc&feugiat=rhoncus&et=dui', '2016-08-14 16:08:49');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (34, 'nullam varius nulla facilisi cras non velit nec nisi vulputate nonummy maecenas tincidunt lacus at velit vivamus vel nulla', 'http://oakley.com/aenean/fermentum/donec.xml?ante=quisque&vivamus=id&tortor=justo&duis=sit&mattis=amet&egestas=sapien&metus=dignissim&aenean=vestibulum&fermentum=vestibulum&donec=ante&ut=ipsum&mauris=primis&eget=in&massa=faucibus&tempor=orci&convallis=luctus&nulla=et&neque=ultrices&libero=posuere&convallis=cubilia&eget=curae&eleifend=nulla&luctus=dapibus&ultricies=dolor&eu=vel&nibh=est&quisque=donec&id=odio&justo=justo&sit=sollicitudin&amet=ut&sapien=suscipit&dignissim=a&vestibulum=feugiat&vestibulum=et&ante=eros&ipsum=vestibulum&primis=ac&in=est&faucibus=lacinia&orci=nisi&luctus=venenatis&et=tristique&ultrices=fusce&posuere=congue&cubilia=diam&curae=id&nulla=ornare&dapibus=imperdiet&dolor=sapien&vel=urna&est=pretium&donec=nisl&odio=ut&justo=volutpat&sollicitudin=sapien&ut=arcu&suscipit=sed&a=augue&feugiat=aliquam&et=erat&eros=volutpat&vestibulum=in&ac=congue&est=etiam&lacinia=justo&nisi=etiam&venenatis=pretium&tristique=iaculis&fusce=justo&congue=in&diam=hac&id=habitasse&ornare=platea&imperdiet=dictumst&sapien=etiam&urna=faucibus&pretium=cursus&nisl=urna&ut=ut&volutpat=tellus&sapien=nulla&arcu=ut&sed=erat&augue=id&aliquam=mauris', '2016-06-08 14:51:54');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (35, 'consectetuer adipiscing elit proin interdum mauris non ligula pellentesque ultrices phasellus id sapien in sapien iaculis', 'https://jigsy.com/vel/accumsan/tellus/nisi/eu.jsp?dui=venenatis&nec=non&nisi=sodales&volutpat=sed&eleifend=tincidunt&donec=eu&ut=felis&dolor=fusce&morbi=posuere&vel=felis&lectus=sed&in=lacus&quam=morbi&fringilla=sem&rhoncus=mauris&mauris=laoreet&enim=ut&leo=rhoncus&rhoncus=aliquet&sed=pulvinar&vestibulum=sed&sit=nisl&amet=nunc&cursus=rhoncus&id=dui&turpis=vel&integer=sem&aliquet=sed&massa=sagittis&id=nam&lobortis=congue&convallis=risus&tortor=semper&risus=porta&dapibus=volutpat&augue=quam&vel=pede&accumsan=lobortis&tellus=ligula&nisi=sit&eu=amet&orci=eleifend&mauris=pede&lacinia=libero&sapien=quis', '2016-04-12 09:22:17');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (36, 'in congue etiam justo etiam pretium iaculis justo in hac habitasse platea dictumst etiam faucibus cursus urna ut tellus nulla ut erat id mauris vulputate elementum nullam varius nulla facilisi cras non velit nec nisi vulputate', 'http://i2i.jp/quam/a/odio/in/hac/habitasse.jpg?ipsum=quis&primis=orci&in=nullam&faucibus=molestie&orci=nibh&luctus=in&et=lectus&ultrices=pellentesque&posuere=at&cubilia=nulla&curae=suspendisse&mauris=potenti&viverra=cras&diam=in&vitae=purus&quam=eu&suspendisse=magna', '2016-06-19 14:52:41');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (37, 'nisi vulputate nonummy maecenas tincidunt lacus at velit vivamus vel nulla eget eros elementum pellentesque quisque porta volutpat erat quisque erat eros viverra eget congue eget semper rutrum nulla nunc purus phasellus in felis donec semper sapien a libero nam dui proin', 'http://issuu.com/molestie.js?orci=maecenas&luctus=ut&et=massa&ultrices=quis&posuere=augue&cubilia=luctus&curae=tincidunt&duis=nulla&faucibus=mollis&accumsan=molestie&odio=lorem&curabitur=quisque&convallis=ut&duis=erat&consequat=curabitur&dui=gravida&nec=nisi&nisi=at&volutpat=nibh&eleifend=in&donec=hac&ut=habitasse&dolor=platea&morbi=dictumst&vel=aliquam&lectus=augue&in=quam&quam=sollicitudin&fringilla=vitae&rhoncus=consectetuer&mauris=eget&enim=rutrum&leo=at&rhoncus=lorem&sed=integer&vestibulum=tincidunt&sit=ante&amet=vel&cursus=ipsum&id=praesent&turpis=blandit&integer=lacinia&aliquet=erat&massa=vestibulum&id=sed&lobortis=magna', '2017-07-28 23:48:40');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (38, 'venenatis non sodales sed tincidunt eu felis fusce posuere felis sed lacus morbi sem mauris laoreet ut rhoncus aliquet pulvinar sed nisl nunc rhoncus dui vel sem sed sagittis nam congue risus semper porta volutpat quam pede lobortis ligula sit amet eleifend pede libero quis orci nullam molestie nibh', 'https://cloudflare.com/nonummy/integer/non/velit/donec/diam.aspx?at=convallis&dolor=tortor&quis=risus&odio=dapibus&consequat=augue&varius=vel&integer=accumsan&ac=tellus&leo=nisi&pellentesque=eu&ultrices=orci&mattis=mauris&odio=lacinia&donec=sapien&vitae=quis&nisi=libero&nam=nullam&ultrices=sit&libero=amet&non=turpis&mattis=elementum&pulvinar=ligula&nulla=vehicula&pede=consequat&ullamcorper=morbi&augue=a&a=ipsum&suscipit=integer&nulla=a&elit=nibh&ac=in&nulla=quis&sed=justo&vel=maecenas&enim=rhoncus&sit=aliquam&amet=lacus&nunc=morbi&viverra=quis&dapibus=tortor&nulla=id&suscipit=nulla', '2017-08-31 16:41:04');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (39, 'elit proin interdum mauris non ligula pellentesque ultrices phasellus id sapien in sapien iaculis congue vivamus metus arcu adipiscing molestie hendrerit at vulputate vitae nisl aenean lectus pellentesque eget nunc donec quis', 'https://sogou.com/nec/nisi/volutpat/eleifend.xml?vestibulum=augue&vestibulum=luctus&ante=tincidunt&ipsum=nulla&primis=mollis&in=molestie&faucibus=lorem&orci=quisque&luctus=ut&et=erat&ultrices=curabitur&posuere=gravida&cubilia=nisi&curae=at&nulla=nibh&dapibus=in&dolor=hac&vel=habitasse&est=platea&donec=dictumst&odio=aliquam&justo=augue&sollicitudin=quam&ut=sollicitudin&suscipit=vitae&a=consectetuer&feugiat=eget&et=rutrum&eros=at&vestibulum=lorem&ac=integer&est=tincidunt&lacinia=ante&nisi=vel&venenatis=ipsum&tristique=praesent&fusce=blandit&congue=lacinia&diam=erat&id=vestibulum&ornare=sed&imperdiet=magna&sapien=at&urna=nunc&pretium=commodo', '2017-06-24 12:22:45');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (40, 'turpis nec euismod scelerisque quam turpis adipiscing lorem vitae mattis nibh ligula nec sem duis aliquam convallis nunc proin at turpis a pede posuere nonummy integer non velit donec diam neque vestibulum eget vulputate ut ultrices vel augue vestibulum ante ipsum', 'http://weather.com/morbi/vel/lectus/in/quam/fringilla/rhoncus.json?urna=nullam&pretium=porttitor&nisl=lacus&ut=at&volutpat=turpis&sapien=donec&arcu=posuere&sed=metus&augue=vitae&aliquam=ipsum&erat=aliquam&volutpat=non&in=mauris&congue=morbi&etiam=non&justo=lectus&etiam=aliquam&pretium=sit&iaculis=amet&justo=diam&in=in&hac=magna', '2016-12-05 21:19:00');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (41, 'diam id ornare imperdiet sapien urna pretium nisl ut volutpat sapien arcu sed augue aliquam erat volutpat in congue etiam justo etiam pretium iaculis justo in', 'http://infoseek.co.jp/eleifend/quam.js?integer=lacus&ac=morbi&leo=sem&pellentesque=mauris&ultrices=laoreet&mattis=ut&odio=rhoncus&donec=aliquet&vitae=pulvinar&nisi=sed&nam=nisl&ultrices=nunc', '2016-07-25 16:22:02');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (42, 'at vulputate vitae nisl aenean lectus pellentesque eget nunc donec quis orci eget orci vehicula condimentum curabitur in libero ut massa volutpat convallis morbi odio odio elementum eu interdum eu tincidunt in leo maecenas pulvinar lobortis est phasellus sit amet erat nulla', 'http://yale.edu/felis/donec/semper/sapien/a.aspx?tempor=sapien&turpis=cum&nec=sociis&euismod=natoque&scelerisque=penatibus&quam=et&turpis=magnis&adipiscing=dis&lorem=parturient&vitae=montes&mattis=nascetur&nibh=ridiculus&ligula=mus&nec=etiam&sem=vel&duis=augue&aliquam=vestibulum&convallis=rutrum&nunc=rutrum&proin=neque&at=aenean&turpis=auctor&a=gravida&pede=sem&posuere=praesent&nonummy=id&integer=massa&non=id&velit=nisl&donec=venenatis&diam=lacinia&neque=aenean&vestibulum=sit&eget=amet&vulputate=justo&ut=morbi&ultrices=ut&vel=odio&augue=cras&vestibulum=mi&ante=pede&ipsum=malesuada&primis=in&in=imperdiet&faucibus=et&orci=commodo&luctus=vulputate&et=justo&ultrices=in&posuere=blandit&cubilia=ultrices&curae=enim&donec=lorem&pharetra=ipsum&magna=dolor&vestibulum=sit&aliquet=amet&ultrices=consectetuer&erat=adipiscing&tortor=elit&sollicitudin=proin&mi=interdum&sit=mauris&amet=non&lobortis=ligula&sapien=pellentesque&sapien=ultrices&non=phasellus&mi=id&integer=sapien&ac=in&neque=sapien&duis=iaculis&bibendum=congue&morbi=vivamus&non=metus&quam=arcu&nec=adipiscing&dui=molestie&luctus=hendrerit&rutrum=at&nulla=vulputate&tellus=vitae&in=nisl&sagittis=aenean&dui=lectus&vel=pellentesque&nisl=eget&duis=nunc&ac=donec&nibh=quis', '2017-01-25 01:13:27');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (43, 'non mi integer ac neque duis bibendum morbi non quam nec dui luctus rutrum nulla tellus in sagittis dui vel', 'https://forbes.com/quam/sollicitudin/vitae/consectetuer/eget.json?felis=neque&donec=aenean&semper=auctor&sapien=gravida&a=sem&libero=praesent&nam=id&dui=massa&proin=id&leo=nisl&odio=venenatis&porttitor=lacinia&id=aenean', '2017-12-08 18:30:22');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (44, 'quam nec dui luctus rutrum nulla tellus in sagittis dui vel nisl duis ac nibh fusce lacus purus aliquet at feugiat non pretium quis lectus suspendisse potenti', 'http://furl.net/dui/vel/sem/sed.png?mi=eleifend&in=pede&porttitor=libero&pede=quis&justo=orci&eu=nullam&massa=molestie&donec=nibh&dapibus=in&duis=lectus&at=pellentesque&velit=at&eu=nulla&est=suspendisse&congue=potenti&elementum=cras&in=in&hac=purus&habitasse=eu&platea=magna&dictumst=vulputate&morbi=luctus&vestibulum=cum&velit=sociis&id=natoque&pretium=penatibus&iaculis=et&diam=magnis&erat=dis&fermentum=parturient&justo=montes&nec=nascetur&condimentum=ridiculus&neque=mus&sapien=vivamus&placerat=vestibulum&ante=sagittis&nulla=sapien&justo=cum&aliquam=sociis&quis=natoque&turpis=penatibus&eget=et&elit=magnis&sodales=dis&scelerisque=parturient&mauris=montes&sit=nascetur&amet=ridiculus&eros=mus&suspendisse=etiam&accumsan=vel&tortor=augue&quis=vestibulum&turpis=rutrum&sed=rutrum&ante=neque&vivamus=aenean&tortor=auctor&duis=gravida&mattis=sem&egestas=praesent&metus=id&aenean=massa&fermentum=id&donec=nisl&ut=venenatis&mauris=lacinia&eget=aenean&massa=sit&tempor=amet&convallis=justo&nulla=morbi&neque=ut&libero=odio&convallis=cras&eget=mi', '2017-08-24 16:36:21');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (45, 'luctus et ultrices posuere cubilia curae donec pharetra magna vestibulum aliquet ultrices erat tortor sollicitudin mi sit amet lobortis sapien sapien non mi integer ac neque duis bibendum morbi non', 'http://bbc.co.uk/elit/ac/nulla/sed/vel.png?platea=nec&dictumst=nisi&morbi=volutpat&vestibulum=eleifend&velit=donec&id=ut&pretium=dolor&iaculis=morbi&diam=vel&erat=lectus&fermentum=in&justo=quam&nec=fringilla&condimentum=rhoncus&neque=mauris&sapien=enim&placerat=leo&ante=rhoncus&nulla=sed&justo=vestibulum&aliquam=sit&quis=amet&turpis=cursus&eget=id&elit=turpis&sodales=integer&scelerisque=aliquet&mauris=massa&sit=id&amet=lobortis&eros=convallis&suspendisse=tortor&accumsan=risus&tortor=dapibus&quis=augue&turpis=vel&sed=accumsan&ante=tellus&vivamus=nisi&tortor=eu&duis=orci&mattis=mauris&egestas=lacinia&metus=sapien&aenean=quis&fermentum=libero&donec=nullam&ut=sit&mauris=amet&eget=turpis&massa=elementum&tempor=ligula&convallis=vehicula&nulla=consequat&neque=morbi&libero=a&convallis=ipsum&eget=integer&eleifend=a&luctus=nibh&ultricies=in&eu=quis&nibh=justo&quisque=maecenas&id=rhoncus&justo=aliquam&sit=lacus&amet=morbi&sapien=quis&dignissim=tortor&vestibulum=id&vestibulum=nulla&ante=ultrices&ipsum=aliquet&primis=maecenas&in=leo&faucibus=odio&orci=condimentum&luctus=id&et=luctus&ultrices=nec&posuere=molestie&cubilia=sed&curae=justo&nulla=pellentesque&dapibus=viverra&dolor=pede&vel=ac&est=diam&donec=cras&odio=pellentesque', '2017-02-17 08:20:36');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (46, 'augue aliquam erat volutpat in congue etiam justo etiam pretium iaculis justo in hac habitasse platea dictumst etiam faucibus cursus urna ut tellus nulla ut erat id mauris vulputate elementum nullam varius nulla facilisi cras non velit nec nisi vulputate nonummy maecenas tincidunt lacus at velit vivamus', 'http://telegraph.co.uk/est/congue/elementum.jsp?eu=pede&nibh=libero&quisque=quis&id=orci&justo=nullam&sit=molestie&amet=nibh&sapien=in&dignissim=lectus&vestibulum=pellentesque&vestibulum=at&ante=nulla&ipsum=suspendisse&primis=potenti&in=cras&faucibus=in&orci=purus&luctus=eu&et=magna&ultrices=vulputate&posuere=luctus&cubilia=cum&curae=sociis&nulla=natoque&dapibus=penatibus&dolor=et&vel=magnis&est=dis&donec=parturient&odio=montes&justo=nascetur&sollicitudin=ridiculus&ut=mus&suscipit=vivamus&a=vestibulum&feugiat=sagittis&et=sapien&eros=cum&vestibulum=sociis&ac=natoque&est=penatibus&lacinia=et&nisi=magnis&venenatis=dis&tristique=parturient&fusce=montes&congue=nascetur&diam=ridiculus&id=mus&ornare=etiam&imperdiet=vel&sapien=augue&urna=vestibulum&pretium=rutrum&nisl=rutrum&ut=neque&volutpat=aenean&sapien=auctor&arcu=gravida&sed=sem&augue=praesent&aliquam=id&erat=massa&volutpat=id&in=nisl&congue=venenatis&etiam=lacinia&justo=aenean&etiam=sit&pretium=amet&iaculis=justo&justo=morbi&in=ut&hac=odio&habitasse=cras&platea=mi&dictumst=pede&etiam=malesuada&faucibus=in&cursus=imperdiet&urna=et&ut=commodo&tellus=vulputate&nulla=justo&ut=in&erat=blandit&id=ultrices&mauris=enim&vulputate=lorem&elementum=ipsum&nullam=dolor&varius=sit&nulla=amet&facilisi=consectetuer&cras=adipiscing', '2017-06-24 16:54:11');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (47, 'ut massa volutpat convallis morbi odio odio elementum eu interdum eu tincidunt', 'https://fc2.com/suspendisse/ornare.xml?pede=eu&malesuada=mi&in=nulla&imperdiet=ac&et=enim&commodo=in&vulputate=tempor&justo=turpis&in=nec', '2018-03-16 03:36:57');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (48, 'blandit mi in porttitor pede justo eu massa donec dapibus duis at velit eu est congue elementum in hac habitasse platea dictumst morbi vestibulum velit id pretium iaculis diam erat', 'https://ow.ly/nisi/vulputate/nonummy/maecenas.xml?fusce=felis&consequat=fusce&nulla=posuere&nisl=felis&nunc=sed&nisl=lacus&duis=morbi&bibendum=sem&felis=mauris&sed=laoreet&interdum=ut&venenatis=rhoncus&turpis=aliquet&enim=pulvinar&blandit=sed&mi=nisl&in=nunc&porttitor=rhoncus&pede=dui&justo=vel&eu=sem&massa=sed&donec=sagittis&dapibus=nam&duis=congue&at=risus&velit=semper&eu=porta&est=volutpat&congue=quam&elementum=pede&in=lobortis&hac=ligula&habitasse=sit&platea=amet&dictumst=eleifend&morbi=pede&vestibulum=libero&velit=quis&id=orci&pretium=nullam&iaculis=molestie&diam=nibh&erat=in&fermentum=lectus&justo=pellentesque&nec=at&condimentum=nulla&neque=suspendisse&sapien=potenti&placerat=cras&ante=in&nulla=purus&justo=eu&aliquam=magna&quis=vulputate&turpis=luctus&eget=cum&elit=sociis&sodales=natoque&scelerisque=penatibus&mauris=et&sit=magnis&amet=dis&eros=parturient&suspendisse=montes&accumsan=nascetur&tortor=ridiculus&quis=mus&turpis=vivamus', '2017-03-21 22:02:26');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (49, 'et ultrices posuere cubilia curae mauris viverra diam vitae quam suspendisse potenti nullam porttitor lacus at turpis donec posuere metus vitae ipsum aliquam non mauris morbi non lectus aliquam sit amet diam in magna bibendum imperdiet nullam orci pede venenatis non sodales sed tincidunt eu', 'http://jigsy.com/tempor/convallis/nulla/neque/libero/convallis/eget.png?nulla=eget&suspendisse=orci&potenti=vehicula&cras=condimentum&in=curabitur&purus=in&eu=libero&magna=ut&vulputate=massa&luctus=volutpat&cum=convallis&sociis=morbi&natoque=odio&penatibus=odio&et=elementum&magnis=eu&dis=interdum&parturient=eu&montes=tincidunt&nascetur=in&ridiculus=leo&mus=maecenas&vivamus=pulvinar&vestibulum=lobortis&sagittis=est&sapien=phasellus&cum=sit&sociis=amet&natoque=erat&penatibus=nulla&et=tempus&magnis=vivamus&dis=in&parturient=felis&montes=eu&nascetur=sapien&ridiculus=cursus&mus=vestibulum&etiam=proin&vel=eu&augue=mi&vestibulum=nulla&rutrum=ac&rutrum=enim&neque=in&aenean=tempor&auctor=turpis&gravida=nec&sem=euismod&praesent=scelerisque&id=quam&massa=turpis&id=adipiscing&nisl=lorem&venenatis=vitae&lacinia=mattis&aenean=nibh&sit=ligula&amet=nec&justo=sem&morbi=duis&ut=aliquam&odio=convallis&cras=nunc&mi=proin&pede=at&malesuada=turpis&in=a&imperdiet=pede&et=posuere&commodo=nonummy&vulputate=integer&justo=non&in=velit&blandit=donec&ultrices=diam&enim=neque&lorem=vestibulum&ipsum=eget&dolor=vulputate&sit=ut&amet=ultrices&consectetuer=vel&adipiscing=augue&elit=vestibulum', '2017-11-23 10:08:30');
insert into public.Comments (comment_id, content, photo_url, comment_date) values (50, 'neque duis bibendum morbi non quam nec dui luctus rutrum nulla tellus in sagittis dui vel nisl duis ac nibh fusce lacus purus aliquet at feugiat non pretium quis lectus suspendisse potenti in eleifend quam a odio in hac habitasse platea dictumst maecenas ut massa', 'http://columbia.edu/velit/vivamus/vel.png?fusce=nulla&posuere=sed&felis=accumsan&sed=felis&lacus=ut&morbi=at&sem=dolor&mauris=quis&laoreet=odio&ut=consequat&rhoncus=varius&aliquet=integer&pulvinar=ac&sed=leo&nisl=pellentesque&nunc=ultrices', '2017-07-17 18:44:40');

/*POOL*/
insert into public.Poll (poll_id, poll_type, poll_date) values (51,4, '2016-03-19 03:16:51');
insert into public.Poll (poll_id, poll_type, poll_date) values (52,2, '2017-10-30 15:11:30');
insert into public.Poll (poll_id, poll_type, poll_date) values (53,4, '2017-03-28 06:29:28');
insert into public.Poll (poll_id, poll_type, poll_date) values (54,4, '2017-10-26 02:36:59');
insert into public.Poll (poll_id, poll_type, poll_date) values (55,1, '2018-02-03 14:28:18');
insert into public.Poll (poll_id, poll_type, poll_date) values (56,3, '2018-01-07 23:48:12');
insert into public.Poll (poll_id, poll_type, poll_date) values (57,3, '2017-11-25 17:27:06');
insert into public.Poll (poll_id, poll_type, poll_date) values (58,1, '2017-01-12 00:25:12');
insert into public.Poll (poll_id, poll_type, poll_date) values (59,4, '2017-01-01 12:44:53');
insert into public.Poll (poll_id, poll_type, poll_date) values (60, 3, '2017-03-18 03:13:50');

/*POOL_UNIT*/

insert into public.Poll_Unit (name, poll_id) values ('etiam', 54);
insert into public.Poll_Unit (name, poll_id) values ('feugiat et eros vestibulum ac est lacinia nisi venenatis tristique', 54);
insert into public.Poll_Unit (name, poll_id) values ('pede ullamcorper augue a suscipit nulla elit ac nulla sed', 58);
insert into public.Poll_Unit (name, poll_id) values ('non ligula', 51);
insert into public.Poll_Unit (name, poll_id) values ('lorem id ligula suspendisse', 53);
insert into public.Poll_Unit (name, poll_id) values ('morbi ut', 53);
insert into public.Poll_Unit (name, poll_id) values ('magnis dis parturient montes nascetur ridiculus', 53);
insert into public.Poll_Unit (name, poll_id) values ('sed', 56);
insert into public.Poll_Unit (name, poll_id) values ('quam sollicitudin vitae consectetuer eget rutrum at', 57);
insert into public.Poll_Unit (name, poll_id) values ('mauris viverra diam vitae quam', 58);
insert into public.Poll_Unit (name, poll_id) values ('lobortis convallis tortor risus dapibus augue vel accumsan tellus', 58);
insert into public.Poll_Unit (name, poll_id) values ('sollicitudin vitae consectetuer eget rutrum at', 56);
insert into public.Poll_Unit (name, poll_id) values ('eros suspendisse accumsan tortor quis', 56);
insert into public.Poll_Unit (name, poll_id) values ('quis augue luctus tincidunt', 55);
insert into public.Poll_Unit (name, poll_id) values ('sit', 60);
insert into public.Poll_Unit (name, poll_id) values ('posuere nonummy integer non velit donec diam', 58);
insert into public.Poll_Unit (name, poll_id) values ('nibh in lectus pellentesque at nulla suspendisse', 56);
insert into public.Poll_Unit (name, poll_id) values ('quam fringilla rhoncus mauris enim leo rhoncus', 51);
insert into public.Poll_Unit (name, poll_id) values ('vitae nisl aenean lectus pellentesque eget nunc donec quis', 59);
insert into public.Poll_Unit (name, poll_id) values ('consequat ut nulla sed accumsan felis', 54);
insert into public.Poll_Unit (name, poll_id) values ('donec odio justo sollicitudin ut suscipit a', 51);
insert into public.Poll_Unit (name, poll_id) values ('tempor convallis nulla neque libero convallis eget eleifend luctus ultricies', 58);
insert into public.Poll_Unit (name, poll_id) values ('augue', 58);
insert into public.Poll_Unit (name, poll_id) values ('facilisi cras non velit', 57);
insert into public.Poll_Unit (name, poll_id) values ('a feugiat', 58);
insert into public.Poll_Unit (name, poll_id) values ('lacus morbi quis tortor id nulla ultrices aliquet maecenas', 52);
insert into public.Poll_Unit (name, poll_id) values ('vivamus vel nulla eget eros elementum pellentesque quisque porta', 56);
insert into public.Poll_Unit (name, poll_id) values ('et ultrices posuere', 56);
insert into public.Poll_Unit (name, poll_id) values ('elit', 60);
insert into public.Poll_Unit (name, poll_id) values ('ut dolor morbi vel lectus in quam fringilla', 57);

/*JoinPoll_UnitToAuthenticated_User*/

insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (26, 22);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (26, 4);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (17, 20);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (11, 11);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (22, 18);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (26, 17);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (28, 18);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (28, 1);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (5, 30);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (18, 2);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (35, 14);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (19, 4);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (10, 24);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (30, 5);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (11, 29);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (24, 19);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (6, 26);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (32, 18);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (2, 11);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (9, 2);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (29, 18);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (26, 6);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (31, 30);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (4, 6);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (12, 6);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (20, 11);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (17, 27);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (1, 14);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (4, 5);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (15, 8);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (34, 7);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (30, 16);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (30, 11);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (26, 5);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (2, 2);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (3, 29);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (9, 3);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (21, 26);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (11, 8);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (11, 26);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (2, 9);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (27, 14);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (25, 27);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (35, 8);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (14, 17);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (15, 24);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (24, 26);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (9, 22);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (17, 21);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (21, 7);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (26, 16);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (34, 29);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (17, 3);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (27, 24);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (20, 30);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (22, 10);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (33, 16);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (23, 22);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (20, 17);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (30, 18);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (24, 16);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (8, 15);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (13, 7);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (28, 5);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (14, 12);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (24, 17);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (17, 24);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (24, 22);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (13, 12);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (4, 27);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (23, 16);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (27, 17);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (16, 25);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (18, 17);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (17, 12);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (31, 5);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (27, 27);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (24, 28);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (32, 3);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (30, 24);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (20, 9);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (21, 13);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (34, 20);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (14, 20);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (6, 29);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (34, 17);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (3, 28);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (10, 13);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (3, 25);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (4, 14);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (8, 27);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (33, 27);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (34, 4);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (3, 8);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (35, 4);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (6, 14);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (1, 16);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (16, 16);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (28, 27);
insert into public.JoinPoll_UnitToAuthenticated_User (user_id, poll_unit_id) values (6, 1);

/*RATE*/

insert into public.Rate (event_content_id, evaluation) values (61,3);
insert into public.Rate (event_content_id, evaluation) values (62,1);
insert into public.Rate (event_content_id, evaluation) values (63,1);
insert into public.Rate (event_content_id, evaluation) values (64,4);
insert into public.Rate (event_content_id, evaluation) values (65,1);
insert into public.Rate (event_content_id, evaluation) values (66,9);
insert into public.Rate (event_content_id, evaluation) values (67,9);
insert into public.Rate (event_content_id, evaluation) values (68,5);
insert into public.Rate (event_content_id, evaluation) values (69,5);
insert into public.Rate (event_content_id, evaluation) values (60, 9);
insert into public.Rate (event_content_id, evaluation) values (71, 3);
insert into public.Rate (event_content_id, evaluation) values (72, 1);
insert into public.Rate (event_content_id, evaluation) values (73, 2);
insert into public.Rate (event_content_id, evaluation) values (74, 1);
insert into public.Rate (event_content_id, evaluation) values (75, 4);
insert into public.Rate (event_content_id, evaluation) values (76, 2);
insert into public.Rate (event_content_id, evaluation) values (77, 1);
insert into public.Rate (event_content_id, evaluation) values (78, 9);
insert into public.Rate (event_content_id, evaluation) values (79, 7);
insert into public.Rate (event_content_id, evaluation) values (80, 2);
insert into public.Rate (event_content_id, evaluation) values (81, 5);
insert into public.Rate (event_content_id, evaluation) values (82, 6);
insert into public.Rate (event_content_id, evaluation) values (83, 5);
insert into public.Rate (event_content_id, evaluation) values (84, 9);
insert into public.Rate (event_content_id, evaluation) values (85, 1);
insert into public.Rate (event_content_id, evaluation) values (86, 1);
insert into public.Rate (event_content_id, evaluation) values (87, 9);
insert into public.Rate (event_content_id, evaluation) values (88, 2);
insert into public.Rate (event_content_id, evaluation) values (89, 6);
insert into public.Rate (event_content_id, evaluation) values (90, 4);
insert into public.Rate (event_content_id, evaluation) values (91, 8);
insert into public.Rate (event_content_id, evaluation) values (92, 4);
insert into public.Rate (event_content_id, evaluation) values (93, 1);
insert into public.Rate (event_content_id, evaluation) values (94, 4);
insert into public.Rate (event_content_id, evaluation) values (95, 8);
insert into public.Rate (event_content_id, evaluation) values (96, 4);
insert into public.Rate (event_content_id, evaluation) values (97, 2);
insert into public.Rate (event_content_id, evaluation) values (98, 2);
insert into public.Rate (event_content_id, evaluation) values (99, 3);
insert into public.Rate (event_content_id, evaluation) values (100, 8);


/*saved event*/
insert into public.Saved_Event (user_id, meta_event_id) values (3, 18);
insert into public.Saved_Event (user_id, meta_event_id) values (1, 7);
insert into public.Saved_Event (user_id, meta_event_id) values (3, 8);
insert into public.Saved_Event (user_id, meta_event_id) values (10, 20);
insert into public.Saved_Event (user_id, meta_event_id) values (17, 9);
insert into public.Saved_Event (user_id, meta_event_id) values (4, 3);
insert into public.Saved_Event (user_id, meta_event_id) values (18, 22);
insert into public.Saved_Event (user_id, meta_event_id) values (16, 4);
insert into public.Saved_Event (user_id, meta_event_id) values (25, 16);
insert into public.Saved_Event (user_id, meta_event_id) values (30, 15);
insert into public.Saved_Event (user_id, meta_event_id) values (1, 16);
insert into public.Saved_Event (user_id, meta_event_id) values (12, 8);
insert into public.Saved_Event (user_id, meta_event_id) values (20, 19);
insert into public.Saved_Event (user_id, meta_event_id) values (16, 1);
insert into public.Saved_Event (user_id, meta_event_id) values (10, 4);
insert into public.Saved_Event (user_id, meta_event_id) values (28, 18);
insert into public.Saved_Event (user_id, meta_event_id) values (9, 8);
insert into public.Saved_Event (user_id, meta_event_id) values (28, 10);
insert into public.Saved_Event (user_id, meta_event_id) values (18, 8);
insert into public.Saved_Event (user_id, meta_event_id) values (2, 11);



/*NOTIFICATIONS*/

insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id) values (1, '2016-04-01 15:05:00', 'userReport', true, 2);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id) values (2, '2016-07-31 14:43:29', 'userReport', true, 2);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id) values (3, '2016-04-02 20:44:11', 'userReport', true, 2);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id) values (4, '2016-08-31 04:09:34', 'userReport', false, 2);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id) values (5, '2016-05-10 12:22:15', 'userReport', false, 1);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id) values (6, '2016-11-20 20:46:41', 'userReport', false, 1);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id) values (7, '2016-10-03 08:19:44', 'userReport', false, 1);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id) values (8, '2016-05-12 01:21:23', 'userReport', true, 2);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id) values (9, '2016-06-21 17:25:36', 'userReport', true, 1);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id) values (10, '2016-12-05 19:54:16','userReport',  false, 2);

insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_id) values (11, '2016-09-18 14:15:08', 'eventReport', true, 1, 15);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_id) values (12, '2017-03-14 05:57:59', 'eventReport', true, 2, 15);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_id) values (13, '2016-03-29 13:36:21', 'eventReport', false, 2, 18);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_id) values (14, '2016-12-06 22:48:03', 'eventReport', false, 1, 10);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_id) values (15, '2017-02-02 11:49:33', 'eventReport', false, 1, 22);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_id) values (16, '2016-05-28 07:38:05', 'eventReport', true, 2, 7);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_id) values (17, '2016-11-12 17:16:12', 'eventReport', false, 2, 18);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_id) values (18, '2016-10-06 04:08:01', 'eventReport', true, 2, 2);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_id) values (19, '2016-04-05 23:20:11', 'eventReport', false, 2, 1);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_id) values (20, '2016-10-06 02:45:34','eventReport',  true, 2, 15);

insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_content_id) values (21, '2016-12-24 20:09:20', 'contentReport', false, 1, 14);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_content_id) values (22, '2017-03-07 01:03:46', 'contentReport', true, 2, 99);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_content_id) values (23, '2016-12-11 13:02:48', 'contentReport', false, 1, 62);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_content_id) values (24, '2016-10-22 10:53:47', 'contentReport', true, 1, 99);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_content_id) values (25, '2016-06-28 06:29:15', 'contentReport', true, 2, 33);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_content_id) values (26, '2017-03-23 11:54:20', 'contentReport', false, 2, 47);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_content_id) values (27, '2016-07-03 22:19:41', 'contentReport', false, 2, 89);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_content_id) values (28, '2016-05-26 14:08:25', 'contentReport', false, 1, 57);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_content_id) values (29, '2016-12-04 08:20:32', 'contentReport', true, 2, 90);
insert into public.Notification (notification_id, notification_date, notification_type, checked, administrator_id, event_content_id) values (30, '2016-07-17 15:46:46','contentReport',  true, 1, 55);

/*NOTIFICATIN INTERVINIENT*/
insert into public.Notification_Intervinient (user_id, notification_id) values (30, 1);
insert into public.Notification_Intervinient (user_id, notification_id) values (28, 2);
insert into public.Notification_Intervinient (user_id, notification_id) values (32, 3);
insert into public.Notification_Intervinient (user_id, notification_id) values (14, 4);
insert into public.Notification_Intervinient (user_id, notification_id) values (21, 5);
insert into public.Notification_Intervinient (user_id, notification_id) values (26, 6);
insert into public.Notification_Intervinient (user_id, notification_id) values (14, 7);
insert into public.Notification_Intervinient (user_id, notification_id) values (9, 8);
insert into public.Notification_Intervinient (user_id, notification_id) values (24, 9);
insert into public.Notification_Intervinient (user_id, notification_id) values (24, 10);


/* Verificar numero de bilhetes em stock quando se comprar bilhete*/

CREATE OR REPLACE FUNCTION buy_ticket() RETURNS TRIGGER AS
$BODY$
DECLARE
	num_total_tickets integer;
	num_sold_tickets integer;
BEGIN
	IF tg_op = 'INSERT' THEN
		SELECT type_ticket.num_tickets INTO num_total_tickets
		FROM Type_of_Ticket type_ticket
		WHERE new.type_of_ticket_id = type_ticket.type_of_ticket_id;

		SELECT count(*) INTO num_sold_tickets
		FROM Ticket t
		WHERE t.type_of_ticket_id = NEW.type_of_ticket_id;

		IF num_total_tickets <= num_sold_tickets THEN
			RAISE EXCEPTION 'Unable to sell ticket. No more tickets to sell. (%) (%)', num_total_tickets, num_sold_tickets;
		END IF;
	END IF;
	RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER buy_ticket
BEFORE INSERT ON Ticket
FOR EACH ROW
EXECUTE PROCEDURE buy_ticket();

/* Insere owner na tabela host do evento quando cria evento*/
CREATE OR REPLACE FUNCTION add_owner_as_host() RETURNS TRIGGER AS
$BODY$
BEGIN
	IF tg_op = 'INSERT' THEN
		INSERT INTO host(user_id, meta_event_id) VALUES (NEW.owner_id, NEW.meta_event_id);
	END IF;
	RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER add_owner_as_host
AFTER INSERT ON Meta_Event
FOR EACH ROW
EXECUTE PROCEDURE add_owner_as_host();

/*Delete Event Content*/

CREATE OR REPLACE FUNCTION delete_event_content() RETURNS TRIGGER AS
$BODY$
BEGIN
	IF tg_op = 'DELETE' THEN

		DELETE FROM Notification WHERE OLD.event_content_id = Notification.event_content_id;
		DELETE FROM Comments WHERE OLD.event_content_id = Comments.comment_id;
		DELETE FROM Rate WHERE OLD.event_content_id = Rate.event_content_id;
		DELETE FROM Poll WHERE OLD.event_content_id = Poll.poll_id;
	END IF;
	RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER delete_event_content
BEFORE DELETE ON Event_Content
FOR EACH ROW
EXECUTE PROCEDURE delete_event_content();


/*Delete Poll*/

CREATE OR REPLACE FUNCTION delete_poll() RETURNS TRIGGER AS
$BODY$
BEGIN
	IF tg_op = 'DELETE' THEN

		DELETE FROM Poll_Unit WHERE OLD.poll_id = Poll_Unit.poll_id;

	END IF;
	RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER delete_poll
BEFORE DELETE ON Poll
FOR EACH ROW
EXECUTE PROCEDURE delete_poll();

/*verifica se é possivel fazer update a um evento (visto que ja passou da data)*/
CREATE OR REPLACE FUNCTION change_event() RETURNS TRIGGER AS
$BODY$
DECLARE
	event_date TIMESTAMP;
BEGIN
	IF tg_op = 'UPDATE' THEN

		SELECT beginning_date INTO event_date
		FROM public.Event
		WHERE public.Event.event_id = OLD.event_id;

		IF event_date <= now() THEN
			RAISE EXCEPTION 'Event passed';
		END IF;

	END IF;
	RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER change_event
BEFORE UPDATE ON public.Event
FOR EACH ROW
EXECUTE PROCEDURE change_event();


/*Blocks Administrator*/
CREATE OR REPLACE FUNCTION block_administrator() RETURNS TRIGGER AS
$BODY$
DECLARE
	num_total_admins INTEGER;
BEGIN
	IF tg_op = 'UPDATE' THEN

		IF NEW.active IS FALSE THEN

			SELECT COUNT(administrator_id) INTO num_total_admins
			FROM Administrator a
			WHERE a.active = true;

			IF num_total_admins <= 1 THEN
				RAISE EXCEPTION 'Unable to delete administrator. Just exists this one!';
			END IF;

		END IF;

	END IF;
	RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER block_administrator
BEFORE UPDATE OF active
ON Administrator
FOR EACH ROW
EXECUTE PROCEDURE block_administrator();


/*Adicionar Notification */
CREATE OR REPLACE FUNCTION add_notification() RETURNS TRIGGER AS
$BODY$
DECLARE
	isActive BOOLEAN;
BEGIN
	IF tg_op = 'INSERT' THEN

		SELECT active INTO isActive
		FROM Administrator
		WHERE administrator_id = NEW.administrator_id;

		IF isActive IS FALSE THEN
			RAISE EXCEPTION 'Cannot add Notification. Administrator does not exist';
		END IF;

	END IF;
	RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER add_notification
BEFORE INSERT	ON Notification
FOR EACH ROW
EXECUTE PROCEDURE add_notification();

