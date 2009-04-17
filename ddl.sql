create table events
(
	title varchar(255),
	location varchar(255),
	start_time varchar(10),
	end_time varchar(10),
	date varchar(100),
	contact varchar(255),
	host varchar(100),
	website varchar(1000),
	description varchar(1000),
	creator varchar(30),
	e_id serial NOT NULL primary key
);