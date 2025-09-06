-- ######################################## Database Creation ########################################

/* 
POSTGRES
a database management system (DBMS) is a software application that interacts with the user, applications and the database
itself to capture and analyse data. the data stored in the database can be modified, retrieved and deleted.
and can be of any type like strings, numbers, images, etc... 

-- command line codes:
psql -U username databaseName  => login to database from cmd | example : psql -U postgres


\q => quit the database
\c databaseName => switch to another database
\l => shows list of all databases
\d => shows all tables and relations in current database
\dt => only show tables
\d tableName => describes a specific table
\i C:Users/Bob/Downloads/script.sql => runs the sql script

-- export selected data from postgres to csv file:
\copy (select * from person) TO 'C:/Users/Bob/Downloads/results.csv' DELIMITER ',' CSV HEADER;
*/

-- create and delete database
create database database1; -- create database
drop database database1;   -- delete database

/*
Schema vs Database

a database is the main container, it contains data and log files, and all schemas within it, you can always backup
a database, it is a discrete unit on its own.

Schemas are like folders within a database, and are mainly used to group logical objects together, which leads to ease of
setting permissions by schema.

schema should be created inside a database. the basic syntax of CREATE SCHEMA is as follows:
CREATE SCHEMA name;
*/

create schema mySchema;

create table mySchema.myTable (
    ...
);

create table mySchema.company(
    ID INT NOT NULL,
    NAME VARCHAR (20) NOT NULL,
    AGE INT NOT NULL,
    ADDRESS CHAR (25),
    SALARY DECIMAL (18, 1),
    PRIMARY KEY (ID)
);

drop schema mySchema cascade;  -- drop full schema with tables with rows inside
drop schema mySchema;  -- drop empty schema


-- create table
-- create table table_name (column_name + data_type + constraints( if any));
-- delete table
-- drop table table_name;

create table person (
    id int,
    first_name varchar (50),
    last_name varchar (50), 
    gender varchar (6),
    date_of_birth timestamp
);

create table person_guarded (
    id bigserial not null primary key,
    first_name varchar (50) not null,
    last_name varchar (50) not null,
    gender varchar(7) not null,
    date_of_birth date not null,
    email varchar (100),
    country_of_birth varchar (150) not null
);

-- Drop VS Drop if exists
-- Standard SQL syntax is
DROP TABLE table_name;  -- throws an error if table doesn't exists

-- IF EXISTS is not standard; different platforms might support it with different syntax, or not support it at all. In PostgreSQL, the syntax is
DROP TABLE IF EXISTS table_name;


-- Data Types

bigserial  -- signed integer that auto increments

-- data types of numeric type:
numeric
smallint
integer
bigint
decimal
double -- has to define precision for it

-- INT => an integer value: 123 , a whole number, from -2 billion to +2 billion for INT (up to 4kb)

money -- the 'money' type stores a currency amount with a fixed fractional precision. values of numeric

boolean -- true or false or null value

character varying (N)  -- variable length with limit
varchar (N) -- variable length with limit
text -- variable with unlimited length, often used for storing long-form text that doesn't fit within the size constrain of VARCHAR 

-- first number = how many digits before decimal point 19
-- second number = how many digits after decimal point 2
price NUMERIC (19, 2) NOT NULL 

-- Serials : all serials are auto incremented
smallSerial
serial
-- BIGSERIAL : it is same as BIGINT but has auto increment function and can also be incremented by the user if invoked.
bigserial

/*
UUID = universally unique identifier, uuid is a type of identifier that is pretty much impossible to be duplicate of another uuid and
can be used as primary key in postgres databases

benefits of using uuid instead of BIGINT:
    it will be harder for attackers to guess the sequence of ids in our database
    easier to migrate database to other locations
*/

date 
-- a specific date without time, format YYYY-MM-DD : 2021-02-06

timestamp
-- a specific date and time without timezone, format YYYY-MM-DD HH:MI:SS : 2021-02-06 15:04:05

-- Manipulate Tables
CREATE TABLE 
INSERT INTO
ALTER TABLE
        ADD
        RENAME COLUMN
        ALTER COLUMN
        DROP COLUMN
DROP TABLE

create extension if not exists "uuid-ossp";  -- installs uuid extension on postgres

-- setting foreign keys with uuid
update person 
set car_uid = '17d11cd6-a272-477d-83c3-1f164c619624'
where person_id = 'ed0fd5a9-f7db-48ed-966a-e8c9517b8276'

-- PRIMARY KEY : is a unique key for each row of the table and can't be repeated since its unique.
-- you can't add primary key to a table when there are duplicate rows.

alter table person add primary key (id); -- add already existing row "id" as primary key
alter table person drop constraint person_pkey; -- how to remove a primary key

-- If a group of columns are defined as a primary key, they are called a "composite key". 
-- That means the combination of values in these columns will uniquely identify the rows in the table.
CREATE TABLE IF NOT EXISTS customer_transactions (
    customer_id int,
    store_id int,
    spent numeric,
    PRIMARY KEY (customer_id, store_id)  -- composite primary key
);

-- ALTER TABLE

-- adding column to a table
alter TABLE table_name ADD column_name data_type;

-- drop column from table
alter TABLE table_name DROP column column_name;

-- change datatype of a column
alter TABLE table_name ALTER column column_name type new_data_type;

-- set column to not null
ALTER TABLE table_name ALTER COLUMN column_name SET NOT NULL;

-- adding unique constraint, so there won't be any repetition in the column cells, here the combination of column1, column2, column3 should not be repeated 
ALTER TABLE table_name ADD CONSTRAINT MyUniqueConstraint UNIQUE (column1, column2, column3);

-- add check constraint
ALTER TABLE table_name ADD CONSTRAINT MyCheckConstraint CHECK (condition);

-- We have a students table, and we want to make sure the age column only allows values between 18 and 100
ALTER TABLE students ADD CONSTRAINT age_check CHECK(age >= 18 AND age < 60);

-- add column with specific allowed values
job_title VARCHAR(20) NOT NULL CHECK (job_title IN ("Engineer", "Technician", "Manager"))

-- add it to already existing column
ALTER TABLE distributors
ADD CONSTRAINT check_types
CHECK (element_type = 'lesson' OR element_type = 'quiz');

-- ❌ This will fail (age too low)
INSERT INTO students (name, age) VALUES ('Joanna', 15);

-- INDEX
/*
Indexes are special lookup tables that the database search engine can use to speed up data retrieval. Simply put, an index is a
pointer to data in a table. An index in a database is very similar to an index in the back of a book. For example, if you want
to reference all pages in a book that discusses a certain topic, you have to first refer to the index, which lists all topics
alphabetically and then refer to one or more specific page numbers. An index helps to speed up SELECT queries and WHERE clauses;
however, it slows down data input, with UPDATE and INSERT statements. Indexes can be created or dropped with no effect on the data.
*/

CREATE INDEX index_name ON table_name
[USING method]
(
    column_name [ASC | DESC] [NULL {FIRST | LAST}],
    ...
);

/* First, specify the index name after the "CREATE INDEX" clause. The index name should be meaningful and easy to remember.
Second, specify the name of the table to which the index belongs to. Third, specify the index method such as btree, hash,
gist, spgist, gin, and brin.
POSTGRES uses btree by default.
Fourth, list one or more columns that to be stored in the index. The ASC and DESC specify the sort order.
ASC is the default. NULLS FIRST or NULLS LAST specifies nulls sort before or after non-nulls.
The NULLS FIRST is the default when DESC is specified and NULLS LAST is the default when ASC specified.
*/

-- this way search will give results much faster when searching for model of a car
create index idx_model on car (model); 

-- multi-column indexing
create index index_name on table_name (column_name1, column_name2);

-- CONSTRAINTS | UNIQUE | CHECK

-- check if there are any duplicate emails
select email, count(*) from person group by email HAVING count(*) > 1;

-- Using this has similar results as above except that the rows with empty email will return 0:
select email, count(email) from person group by email;

-- Add unique constraint to emails, here we gave it a name but it is not necessary:
-- unique constraint can’t be used to identify rows (unlike primary key)
alter table person add constraint unique_email unique(email);

-- make sure salary input is above 0 by CHECK constraint
create table company (
    id int primary key not null,
    name text not null,
    salary real check(salary > 0)
);

-- making sure a column has only 2 input options
ALTER TABLE person ADD CONSTRAINT gender_constraint CHECK (gender = 'Female' or gender = 'Male')

-- Truncate
/*
The PostgreSQL TRUNCATE TABLE command is used to delete the whole data from an existing table. You can also use DROP TABLE
command to delete complete table but it would remove table structure from the database and you would need to re-create this
table once again if you wish to store some data.
It has the same effect as DELETE on each table, but since it does not actually scan the tables, it is faster. Furthermore,
it reclaims disk space immediately, rather than requiring a subsequent VACUUM operation. This is most useful on large tables.
*/
TRUNCATE TABLE table_name;


-- RELATIONSHIPS between Tables
-- there are 3 types of relationships in a relational database.
-- one-to-one : A user has ONE address
-- one-to-many : A book has MANY reviews
-- many-to-many : A user has MANY books and a book has MANY users

-- one-to-one
/* 
primary key and foreign key both have same type. (here is One-To-One relationship): means id column in car table should have same
data type as car_id foreign-key in person table 
*/
create table car (
    id bigint not null primary key,
    make varchar (100) not null,
    model varchar (100) not null,
    price numeric (19, 2) not null
);

-- we create car table first because the person table needs the foreign-key from car table
create table person (
    id bigserial not null primary key,
    first_name varchar (50) not null,
    last_name varchar (50) not null,
    email varchar (100),
    car_id bigint REFERENCES car(id),  -- foreign-key
    UNIQUE(car_id) -- two people can't own one car, this is a constraint
);

-- Add foreign key between car and person tables, car_id is same as id column in car table:
update person set car_id = 2 where id = 1;
update person set car_id = 1 where id = 3;

-- since this is a 1-to-1 relationship, each item can only connect to one other row of other table

-- one-to-many
/*
A one-to-many relationship exists between two entities if an entity instance in one of the tables can be associated with multiple
records (entity instances) in the other table. The opposite relationship does not exist; that is, each entity instance in the second table
can only be associated with one entity instance in the first table.  
*/

create table user (
    id serial,
    username varchar (25) not null,
    enabled boolean default TRUE,
    last_login timestamp not null default NOW(),
    primary key (id)
);

-- one to one: User has one address
create table address (
    user_id int not null,
    street varchar(30) not null,
    city varchar(30) not null,
    state varchar(30) not null,
    primary key (user_id), -- foreign-key and primary-key both are same value here!
    constraint fk_user_id foreign key (user_id) reference user(id)
);

create table books (
    id serial,
    title varchar(30) not null,
    author varchar(30) not null,
    published_date timestamp not null,
    isbn int,
    primary key (id),
    unique (isbn)
);

-- one to many: Book has many reviews
drop table if exists reviews;
create table reviews (
    id serial,
    book_id int not null,
    user_id int not null,
    review_content text,
    rating int,
    published_date timestamp DEFAULT current_timestamp,
    primary key (id),
    foreign key (book_id) references books(id) on delete cascade,
    foreign key (user_id) references users(id) on delete cascade
);

/* 
when rows have relation with another table (foreign key) you can’t normally delete them.first delete the
row that contains the foreign key, then u can delete the row that is being referenced in other table.

** with cascading, when you delete a row the related row with foreign key in other table will also be
deleted. (its considered a BAD practise) 
*/

-- many-to-many
/*
A many-to-many relationship exists between two entities if for one entity instance there may be multiple records in the other table and vice versa.
Example: A user has many books checked out or may have checked them out in the past. A book has many users that have checked a book out.
In the database world, this sort of relationship is implemented by introducing a third cross-reference table, that holds the relationship
between the two entities, which is the PRIMARY KEY of the books table and the PRIMARY KEY of the user table. 
*/

create table users_books (
    user_id int not null,
    book_id int not null,
    checkout_date timestamp,
    return_date timestamp,
    primary key (user_id, book_id),  -- composite primary key that is made of two foreign keys
    foreign key (user_id) references users(id) on update cascade,
    foreign key (book_id) references books(id) on update cascade
);

-- DATABASE DESIGN
	
/* Write SQL queries that create DB schema to store people located all over the world, data to store:
a. Name
b. Surname
c. Citizenship
then Write SQL queries that add parents information (mother, father) to existing schema */
CREATE SCHEMA mySchema;

CREATE TABLE mySchema.countries (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE mySchema.people (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    country_id INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (country_id) REFERENCES countries(id) ON DELETE CASCADE
);

ALTER TABLE mySchema.people ADD father BIGINT;
ALTER TABLE mySchema.people ADD CONSTRAINT FOREIGN KEY (father) REFERENCES people(id);

ALTER TABLE mySchema.people ADD mother BIGINT;
ALTER TABLE mySchema.people ADD CONSTRAINT FOREIGN KEY (mother) REFERENCES people(id);

-- find all the people who are father or mother to another person in this table
SELECT DISTINCT(p1.id), p1.name, p1.surname
FROM mySchema.people as p1
JOIN mySchema.people as p2
on p2.father = p1.id OR p2.mother = p1.id;


-- ######################################## Querying Database ########################################


-- Insertion into database
insert into person(first_name, last_name, gender, date_of_birth) 
values ('Anne', 'Smith', 'F', '1988-01-09');

insert into person(first_name, last_name, gender, date_of_birth, email)
values ('Jake', 'Sanderson', 'M', date '1994-09-16', 'jake@gmail.com');

insert into mytable set x=1, y=2 on duplicate key update x=x+1 , y=y+2;

-- Querying database
select * from table_name; -- get everything from a table
select from table_name; -- get number of all rows from a table

-- explicit naming of rows is better than using *, as its more readable
select * from emp;
select empno, ename, job, sal, mgr, hiredate, comm, deptno from emp;

select first_name, last_name from person;

-- ASC / DESC
-- ASC : 1 2 3 A B C
-- DESC : 3 2 1 C B A

-- order by
select * from person order by country_of_birth asc; -- ASC is the default so it is not necessary to write it.
select * from person order by country_of_birth desc;  -- last to first, Z to A
select * from person order by id desc; -- last row is first

-- when you order by descending, it will first show the rows that are EMPTY for the descending column
select * from person order by date_of_birth; -- goes from small to big so it moves from oldest to youngest person

SELECT ename, job 
FROM emp
-- grabs the last 2 characters of the job title (because by default SUBSTR grabs from the start position to the end of the string)
ORDER BY SUBSTR(job, LENGTH(job)-1);  -- sort by last two characters of job

-- null values are smaller than 0 so they will be last here (no sorting for them)
select ename, sal, comm from emp order by 3;

-- non null comm sorted asc, all nulls last
select ename, sal, comm
from (
    select ename, sal, comm, 
    case when comm is null then 0 else 1 end as is_null from emp
) x
order by is_null desc, comm;


-- DISTINCT
-- only unique values will be returned
select distinct country_of_birth from person order by country_of_birth desc;
select distinct first_name from person;

select DISTINCT
	jpc.job_id AS jid,
    jpc.job_title AS jtitle
from
	job_postings_fact AS jpc;

-- WHERE | AND | OR
select * from person where gender = 'Female';
select * from person where gender = 'Male' and country_of_birth = 'Poland';
select * from person where gender = 'Male' and (country_of_birth='China' or country_of_birth='Japan');

select
	job_title_short, job_via, salary_year_avg
from
	job_postings_fact
where not
	job_via = 'via Ai-Jobs.net';

-- How to perform string does not equal
select * from table_test where tester <> 'x_username' or tester is not null;


select * from person 
where gender = 'fluid' 
and (country_of_birth='Sweden' or country_of_birth='Denmark') 
and last_name='Eriksson';

-- LIMIT | OFFSET
select * from person limit 10; -- show 10 rows
select * from person offset 5; -- all rows except first 5

-- skip first 5 rows and limit to 5 (so rows 6 to 10)
select * from person offset 5 fetch first 5 row only; 
select * from person offset 5 limit 5; -- skip first 5 rows and limit to 5

-- IN
select * from person where country_of_birth = 'China' or country_of_birth='Brazil' or country_of_birth = 'France' limit 10;
select * from person where country_of_birth in ('China', 'Brazil', 'France') limit 10;

-- BETWEEN
select * from person where date_of_birth between date '2018-01-01' and date '2020-09-30';

select
	job_title_short, salary_year_avg
from
	job_postings_fact
where
	job_title_short = 'Data Analyst' and salary_year_avg between 60000 and 90000
order by 
	salary_year_avg 
limit 20;

-- aliasing
select sal as salary, comm as commision from emp;

select * 
from (select sal as salary, comm as commision from emp) x 
where salary < 5000;

SELECT * -- this is needed because where clasue is executed before subquery select
FROM (
    SELECT sal AS salary, comm AS commission 
    FROM emp
) x -- inline view aliased as x
WHERE salary < 5000;

select ename||' works as a '||job as msg  -- Clark works as a manager
from emp
where deptno = 10;

-- show only even or odd rows
select * from men where (rowid % 2) = 1; -- odd
select * from men where (rowid % 2) = 0; -- even

-- NULL, NOT NULL
select * from person where car_id is null;  -- all rows where this column is empty, person doesn't have a car
select * from person where car_id is not null;  -- all rows where column is not empty

-- LIKE | ILIKE | wild cards
select * from person where email like '%.com';  -- the email should end with '.com'
select * from person where email like '%.ru' order by email desc;
select * from person where email like '%@bloomberg.com';
-- using two wild cards, when after % is empty it means anything can go here
select * from person where email like '%@google.%';
-- select all people where their email has 4 characters before @
select * from person where email like '____@%';
select * from person where country_of_birth like 'U%' limit 5;
select * from person where country_of_birth ilike 'f%' limit 5; -- ILIKE is same as LIKE, but it is case insensitive

select ename, job from emp where deptno in (10, 25, 30, 50) and (ename like '%I%' OR job like '%ER');

-- get random set of records from table
select ename, job from emp order by random() limit 5;

-- AGGREGATE FUNCTIONS

-- make groups based on each unique value of the column
select country_of_birth from person group by country_of_birth;

-- COUNT
COUNT() -- is an aggregate function and can't be used without a group by, where,...

-- count method counts number of each record for each of the groups made with group by
select country_of_birth, count(*) 
from person 
group by country_of_birth
order by count(*) desc;

-- HAVING keyword should be used right after group by clause
select country_of_birth, count(*)
from person
group by country_of_birth
having count(*) > 7   -- each country_of_birth group should have at least 7 rows of results
order by count(*) desc;

select gender, count('Male') from person group by gender;
select count(*) from car;  -- shows total row count, same as 'select from car'

-- MAX | MIN | AVG | SUM
select max(price) from car;
select min(price) from car;
select avg(price) from car;
select round(avg(price)) from car;  -- round down the value to integer

-- group by the cars by brand and model (each unique combination of 'brand and model' is a group) and find minimum price for each of these groups
select make, model, min(price) 
from car 
group by make, model;

select make, max(price) 
from car
group by make
order by max(price) desc;


SELECT 
	job_title_short AS Jobs,
    COUNT(job_title_short) AS job_count,
	AVG(salary_year_avg) as salary_avg,
    MIN(salary_year_avg) as salary_min
FROM 
	job_postings_fact
GROUP BY
	Jobs
HAVING
	COUNT(job_title_short) > 10
ORDER BY
	job_count DESC;

-- group by 1 => In SQL, GROUP BY 1 means you're grouping the results by the first column in your SELECT statement
-- In this case, GROUP BY 1 is the same as: GROUP BY country
SELECT country, COUNT(*) 
FROM cities 
GROUP BY 1;



-- adds up all values of price column for the brand hummer
select sum(price) from car where make='Hummer';
select make, sum(price) from car group by make;
select make, sum(price) from car group by make order by sum(price) desc;

-- what does sql clause "GROUP BY 1" means?
-- it means group by first column from select. the same pattern could be used for order by

-- add two count(*) results together on two different tables
select 
    (select count(*) from toys where little_kid_id = 900) +
    (select count(*) from games where little_kid_id in (900, 950, 1000))
as sumCount;

-- IF in 'SELECT' statement - choose output value based on column values
select id,
    IF(type = 'P', amount, amount * -1) as amount -- if type is P select amount else select amount * -1
from report;

-- selecting count(*) with distinct
-- count all the distinct program names by program type and push number
select count(distinct program_name) as count, program_name
from cm_production
where push_number=@push_number 
group by program_type

select user_id, SUM(sales)
from sales data
where user_id between 300 and 400
group by user_id;

select c.country, c.team, SUM(m.goal)
from countries as c left join matches as m
on c.team_id = m.home_team_id
where m.year > 1994
-- The GROUP BY c.country, c.team means you're grouping by the combination of those two columns — country and team
group by c.country, c.team;

select l.name as league_name, count(m.country_id) as matches
from league as l left join match as m
on l.country_id = m.country_id
group by l.name;


-- AS
select 
    id, 
    model, 
    price AS original_price, 
    round(price * 0.10, 2) AS discount, 
    round(price - (price * 0.10), 2) AS discounted_price
from 
    car;


SELECT
	project_company,
    nerd_id,
    nerd_role,
    hours_rate AS rate_original,
    hours_rate - 5 AS rate_drop,
    hours_rate + 5 AS rate_hike,
    (hours_rate + 5) * hours_spent AS project_total
FROM
	invoices_fact
Where
	project_total > 1000;

select id, make, model, price, round(price * .10, 2) from car;

-- COALESCE | NULLIF
-- COALESCE will return second (or third) value if first (or first and second) value is null
select COALESCE(1);
select COALESCE(null, null, 1) as number;
select COALESCE(email, 'email not provided') from person;

select nullif(10, 10); -- returns true when both values are same
select nullif(10, 3); -- returns false when values are different

-- this way postgres won't throw error for division by zero
select COALESCE(10 / nullif(0, 0), 0);

select coalesce(comm, 0) from emp; -- replaces null with 0

-- DELETE
-- delete ALL ROWS where this condition applies:
delete from person where first_name = 'Noemi';
delete from person where first_name = 'Cass';
delete from person; -- deletes everything from table (so it becomes an empty table)
delete from person where id = 1;
delete from person where gender = 'Female' and country_of_birth = 'Nigeria';
-- how to delete only 1 row:
delete from person where ctid in (select ctid from person where gender='Female' limit 1);

-- UPDATE
update person set email = 'babak@gmail.com' where id = 18;
update person set first_name = 'babak', country_of_birth = 'Iran' where id = 45;

-- SQL how to increase or decrease one for a int column in one command
UPDATE orders SET quantity = quantity + 1 WHERE ... 

-- SubQuery
/*
a subquery or inner query or nested query is a query within another PostgreSQL query and embedded within the where clause.
a subquery is used to return data that will be used in the main query as a condition to further restrict the data to be retrieved.
*/
select * from company where id in (select id from company where salary > 45000);

-- company_two has the same structure (column order and types) as company
insert into company two
select * from company
where id in (select id from company where salary < 10000);

update company set salary = salary * 0.5 where age in (select age from company_bkp where age > 27);

delete from company where age in (select age from company_bkp where age < 18 OR age > 65);

select column from (select column_2 from table) as subquery;

--where home goals are higher than the averge that we have
select home_goal from match where home_goal > (select AVG(home_goal) from match);

-- subquery inside where
select team_long_name, team_short_name from team
-- subquery here comes from another table
where team_api_id in (select hometeam_id from match where home_goal >= 8);

-- here we do not read from a table, but directly from a subquery, so columns team, home_avg should be present in the table that is the result of the subquery
select team, home_avg
from (select t.team_long_name as team, AVG(m.home_goal) as home_avg
      -- get all the match rows and join with team (if it exists, otherwise its NULL for team-name), then only select 2011/2012 season and then group it by each team
      from match as m
      left join team as t
      on m.hometeam_id = t.team_api_id
      where season = '2011/2012'
      -- we group it by team, so that we can get the AVG(m.home_goal) from the list of match's for each team group.
      group by team) as subquery
order by home_avg desc
limit 3;

-- Subtraction between two sql queries
SELECT 
    (SELECT COUNT(*) FROM ... WHRE ...)
    -
    (SELECT COUNT(*) FROM ... WHERE ...)  AS difference


-- When writing queries in SELECT, it's important to remember that filtering the main query does not filter the subquery
-- and vice versa.
SELECT
	name AS l.lname,
	ROUND(AVG(m.home_goal + m.away_goal), 2) AS avg_goals,
	ROUND(AVG(m.home_goal + m.away_goal) - 
        -- here is the subquery
        -- this is only selecting the season = '2013/2014', but it does NOT effect the main query
		(SELECT AVG(home_goal + away_goal) FROM match WHERE season = '2013/2014'), 2) AS diff
FROM league AS l
LEFT JOIN match AS m
ON l.country_id = m.country_id
WHERE m.season = '2013/2014' -- filter again in the main query
GROUP BY l.name; -- we group by league name, so that we can get averge of all the matches in AVG(m.home_goal + m.away_goal)


-- Correlated Sub Queries 
-- subquery : independant, can run on it's own
-- correlated subquery : can Only run with the main querry and not alone!
-- Correlated subqueries are evaluated in SQL "once per row" of data retrieved 

-- normal query with join:
select c.name as country , AVG(m.home_goal + m.away_goal) as avg_goals
from country as c left join match as m
on c.id = m.country_id
group by country;

-- same as above, but with a correlated subquery
select c.name as country,
    -- here we do not write the "join" keyword instead use "where" and c (country) comes from outer query, also grouping comes from outer query
    (select AVG(m.home_goal + m.away_goal) from match as m where m.country_id = c.id) as avg_goals
from country as c
group by country;


-- "Employee" table is only used in the correlated subquery
SELECT lo.locationID, lo.Street, lo.city, (
    SELECT COUNT(*) FROM Employee AS em WHERE em.locationID = lo.locationID
) as empCount
FROM Locations AS lo;


-- what was the highest scoring match for each country, in each season?
-- correlated subquery but only using One table here
SELECT main.country_id, main.date, main.home_goal, main.away_goal
FROM match as main 
WHERE (home_goal + away_goal) = (
    SELECT max(sub.home_goal+sub.away_goal) 
    FROM match AS sub 
    WHERE main.country_id = sub.country_id AND main.season = sub.season
);
-- select country info where total goal (home+away) equals:
-- subquery : max(home+away goals)  When  outer query's country is same as subquery's country AND outer query's season is same as subquery's season

-- examine matches with scores that are extreme outliers for each country
SELECT
    m.country_id,
    m.date,
    m.home_goal,
    m.away_goal
FROM match AS m
WHERE (m.home_goal + m.away_goal) > 
      (
        SELECT AVG(s.home_goal + s.away_goal) * 3
        FROM match AS s
        -- the join clause is always inside the correlated subquery, to glue it together with the main query
        WHERE s.country_id = m.country_id
      );

-- NULL values
/*
NULL is the term used to represent a missing value. a NULL value in a table is a value in a field that appears to be blank.
a "field with a NULL value is a field with no value". it is very important to understand that a null value is different from a zero value
or a field that contains space.  
*/
UPDATE person SET first_name = NULL, email = NULL WHERE id IN (6, 7, 8);
SELECT id, name, age, address, salary FROM company WHERE salary IS NOT NULL;
-- find all null values for a column
SELECT id, name, age, address, salary FROM company WHERE salary IS NULL;


-- JOINS : Left join, Right join, Inner join, Full (outter) join, Cross Join, Self join

-- INNER JOIN : happens when two different tables have something in common (usually a foreign key or row)
-- JOIN same as INNER JOIN
SELECT person.first_name, car.make, car.model 
FROM person JOIN car 
ON person.car = car.id;

-- LEFT JOIN : gets everything from table A + rows from table B that have something in common with A.
SELECT * FROM person LEFT JOIN car ON car.id = person.car_id;
-- Exactly same as, order of tables in equation doesnt matter :
SELECT * FROM person LEFT JOIN car ON person.car_id = car.id;

-- Get everything where table A has nothing in common with B
-- gets all the people who dont own a car
SELECT * FROM person LEFT JOIN car ON person.car_id = car.id WHERE car.* IS null;

-- RIGHT JOIN : same as left join but instead selects all rows from B table and common rows from A.
-- get all rows from car and the rows from persons that has something in common with car
SELECT * FROM person RIGHT JOIN car on car.car_uid = person.car_uid;

-- CROSS JOIN :
/* 
a CROSS JOIN matches every row of the first table with every row of the second table. If the input tables have x and y columns,
respectively, the resulting table will have x*y columns. Because CROSS JOINs have the potential to generate extremely large tables,
care must be taken to use them only when needed  
*/
SELECT * FROM person CROSS JOIN car;

-- FULL JOIN (OUTER JOIN)
/* 
PostgreSQL FULL OUTER JOIN returns all rows from both the participating tables, extended
with nulls if they do not have a match on the opposite table.
The FULL OUTER JOIN combines the results of both left and right joins and returns all
(matched or unmatched) rows from the tables on both sides of the join clause. 
this is NOT very common to use!
*/
-- FULL JOIN same as FULL OUTER JOIN
select * from person FULL JOIN car on car.car_uid = person.car_uid;
select car.model, person.email from person FULL JOIN car on car.car_uid = person.car_uid;

-- Finding Matched Rows with FULL OUTER JOIN
select * from accounts full join sales_reps on accounts.sales_rep_id = sales_reps.id

-- unmatched rows with full outer join
select * from accounts full join sales_reps
on accounts.sales_rep_id = sales_reps.id
where accounts.sales_rep_id is null or sales_rep_id.id is null;

select 
    job_postings.job_id,
	job_postings.job_title_short,
    companies.name
FROM job_postings_fact AS job_postings LEFT JOIN company_dim AS companies
ON job_postings.company_id = companies.company_id;


select 
  job_postings.job_id, 
  job_postings.job_title,
  skills_to_jobs.skill_id,
  skills.skills
FROM job_postings_fact AS job_postings
JOIN skills_job_dim AS skills_to_jobs ON job_postings.job_id = skills_to_jobs.job_id  -- first inner join
JOIN skills_dim AS skills ON skills_to_jobs.skill_id = skills.skill_id; -- second inner join, this happens AFTER first inner join is done

-- USING
-- when both keys are same you can use the 'USING' keyword:
select * from person left join car on car.car_uid = person.car_uid;
-- same as:
select * from person left join car USING (car_uid);

-- UNION
/* 
The PostgreSQL UNION clause/operator is used to combine the results of two or more SELECT statements without returning any duplicate rows.
To use UNION, each SELECT must have the same number of columns selected, the same number of column expressions, the same data type and have
them in the same order but they do not have to be the same length.

UNION => removes duplicate rows

The UNION ALL operator is used to combine the results of two SELECT statements including duplicate rows 

UNION merges the contents of two structurally-compatible tables into a single combined table. The difference between UNION 
and UNION ALL is that UNION will omit duplicate records whereas UNION ALL will include duplicate records.
*/

select column1 [, column2]
from table1 [, table2]
[where condition]

UNION

SELECT column1 [, column2 ]
FROM table1 [, table2 ]
[WHERE condition]

select first_name, email from person where first_name = 'Jal'
union
select first_name, email from person where first_name = 'Robert';

-- inequality joins (with comparison operator)
SELECT accounts.name as account_name,
       accounts.primary_poc as poc_name,
       sales_reps.name as sales_rep_name
FROM accounts LEFT JOIN sales_reps
ON accounts.sales_rep_id = sales_reps.id
AND accounts.primary_poc < sales_reps.name;   -- this is the comparision section of the join


-- the "join" clause is evaluated before the "where" clause, filtering in the join clause will eliminate rows before
-- they are joined, while filtering in the WHERE clause will leave those rows in and produce some nulls.
select orders.id, orders.occured_at as order_date, events.*
from orders left join web_events_full AS events 
on events.account_id = orders.account_id  -- the main left join clause
and events.occured_at < orders.occured_at -- the inequality clause that is added to join 
where date_trunc("month", orders.occured_at) = (select date_trunc("month", min(occured_at)) from orders)  -- this will happen AFTER the Join clause, so it will not improve the join performance!
order by orders.account_id ,orders.occured_at;  -- at end order the result of the join by account_id


-- SELF JOIN
-- One of the most common use cases for self JOINs is in cases where two events occurred, one after another
-- ** finding out which account made multiple orders within 30 days **
select 
    o1.account_id as o1_account_id,
    o1.occured_at as o1_o1_occured_at,
    -- o1 and o2 are SAME table!
    o2.id as o2_id
    o2.account_id as o2_account_id,
    o2.occured_at as o2_occured_at,
-- we join the table to itself, by giving it two names
from demo.orders as o1 left join demo.orders as o2
    on o1.account_id = o2.account_id -- we want the same account
    and o2.occured_at > o1.occured_at -- we need an account with at least two different orders
    and o2.occured_at <= o1.occured_at + interval '28 days' -- but the second orders date must be less than 29 days after first one
order by o1.account_id, o1.occured_at;

-- IF-ELSE logic in SQL
IF ((SELECT COUNT(*) FROM table1 WHERE project = 1) > 0)
    SELECT product, price FROM table1 WHERE project = 1
ELSE IF ((SELECT COUNT(*) FROM table1 WHERE project = 2) > 0)
    SELECT product, price FROM table1 WHERE project = 2
ELSE IF ((SELECT COUNT(*) FROM table1 WHERE project = 3) > 0)
    SELECT product, price FROM table1 WHERE project = 3

-- CASE Statement
CASE
    WHEN condition_1 THEN results_1
    WHEN condition_2 THEN result_2
    [WHEN...]
    [ELSE result_n]
END

select
-- this will add up all rows that have their 'rental_rate' column set to 0.99, sums each one as 1+1+1+...
sum (case
    when rental_rate = 0.99 then 1
    else 0
    end) as "Mass",
sum (case
    when rental_rate = 2.99 then 1
    else 0
    end) as "Economics"
sum (case
    when rental_rate = 4.99 then 1
    else 0
    end) as "Luxury"
from film;


select
-- case statement for either selecting a column or leaving it as NULL based on a value
case 
    when grade >= 8 then name
    when grade < 8 then null
end as NAME, grade, marks
-- here we have a left join using BETWEEN instead of =  (will result on one-to-many)
from students left join grades on students.marks between grades.min_mark and grades.max_mark
order by grade desc,
-- here we use case to choose the second column that the results will be sorted on, if value for first column is same
case
    when grade >= 8 then name
    when grade < 8 then marks
end asc;

-- case statement with group by
SELECT 
	CASE WHEN hometeam_id = 10189 THEN 'FC Schalke 04'
         WHEN hometeam_id = 9823 THEN 'FC Bayern Munich'
         ELSE 'Other' END AS home_team,
    COUNT(id) AS total_matches
FROM matches_germany
GROUP BY home_team;


-- case statement with join
SELECT 
	m.date,
	t.team_long_name AS opponent, 
    -- home_goal => home team's goals  |  away_goal => away team's goals
	CASE WHEN m.home_goal > m.away_goal THEN 'Home win!'
         WHEN m.home_goal < m.away_goal THEN 'Home loss :('
         ELSE 'Tie' END AS outcome
FROM matches_spain AS m
LEFT JOIN teams_spain AS t
-- we join on 'awayteam_id' because we want to show name of the oponents (t.team_long_name AS opponent), so id of that team needs to exist in teams_spain table in order to fetch it's name
ON m.awayteam_id = t.team_api_id;


-- Case inside Where statement
SELECT season, date, home_goal, away_goal
FROM matches_italy
-- 'Bologna Win' : is a dummy statement for the CASE clause, 'Bologna Win' is a placeholder value just to make the CASE return something non-null.
WHERE CASE WHEN hometeam_id = 9857 AND home_goal > away_goal THEN 'Bologna Win'
           WHEN awayteam_id = 9857 AND away_goal > home_goal THEN 'Bologna Win'
           -- So the WHERE clause filters only rows where Bologna won, because only in those cases the CASE returns 'Bologna Win' All other rows (losses or ties) will result in NULL, and be excluded
           END IS NOT NULL;

-- query above works same as query below:
SELECT season, date, home_goal, away_goal
FROM matches_italy
WHERE (hometeam_id = 9857 AND home_goal > away_goal)
   OR (awayteam_id = 9857 AND away_goal > home_goal);


-- case with count()
-- 1. JOIN => SQL combines rows from country and match based on the ON condition
-- 2. GROUP BY => After the join, SQL groups the resulting rows by c.name
-- 3. COUNT with CASE => For each group (i.e. for each country), it counts how many matches fall into each season
SELECT
    c.name AS country,
    -- through case, the m.season that is one column, becomes several values
    -- Count matches in each of the 3 seasons
    count(case when m.season = '2012/2013' then m.id end) AS matches_2012_2013,
    count(case when m.season = '2013/2014' then m.id end) AS matches_2013_2014,
    count(case when m.season = '2014/2015' then m.id end) AS matches_2014_2015
FROM country AS c
LEFT JOIN match AS m
ON c.id = m.country_id
--  JOIN happens before the GROUP BY
GROUP BY country;


-- CTE : Common Table Expressions
-- define a temporary result set that you can reference, it only exists during the execution of a query.
-- can reference within a SELECT, INSERT, UPDATE, DELETE statement, always starts with WITH

WITH january_jobs AS ( -- CTE definition starts here
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1
) -- CTE definition ends here

SELECT * FROM january_jobs;

-- setup CTE
with match_list as (
    select country_id, id from match where (home_goal + away_goal) >= 10
)
-- here we are using result of CTE as if it's a separate table
select l.name as lname, count(match_list.id) as matches
-- Join the CTE to the league table
from league as l left join match_list on l.id = match_list.country_id
group by l.name;  -- we are using group by so we can use count on the match_list CTE


-- a CTE made of left join between 2 tables:
with match_list as (
    select l.name as lname, m.date, m.home_goal, m.away_goal, (m.home_goal + m.away_goal) as total_goals
    from match as m left join league as l on m.country_id = l.id
)
-- here we use CTE, and limit the results via a where clause
select lname, date, home_goal, awayteam_id
from match_list
where total_goals >= 10;

-- join on two CTE
with home as (
    select m.id, m.date, t.team_long_name as home_team, m.home_goal
    from match as m left join team as t
    on m.home_team_id = team.team_api_id),
away as (
    select m.id, m.date, t.team_long_name as awayteam, m.away_goal
    from match as m left join team as t
    on match.awayteam_id= team.team_api_id)
-- since we have all data, there is no need to rejoin to match table again
select 
    home.date, home.hometeam, away.team, home.home_goal, away.away_goal
from home join away
-- this is the id of the match from match.id
on home.id = away.id;


-- WINDOW FUNCTIONS
-- the OVER() clause offers significant benefits over subqueries in select, namely, your queries will run faster
-- Used with window functions to define a "window" of rows within the result set for a function to operate on.

select 
    date, 
    (home_goal + away_goal) as goals,
    -- instead of writing subquery to calculate the aggregate, user OVER() : runs over this period to calculate aggregate
    -- with over() we can have AVG function without using groups
    AVG(home_goal+away_goal) over() as overall_goal
from match
where season = '2011/2012';

-- this is similar to "order by desc", but here we order by a custom category
select
    date,
    (home_goal+away_goal) as goals,
    -- The RANK function in SQL is used to assign rank to each row in a result set, based on a given ordering of data
    -- rank window function works in conjunction with over() , which rank to give to a match based on number of goals
    rank() over(order by home_goal+away_goal desc) as goal_rank
from match
where season = '2011/2012';

-- rank football leagues based on their seasonal averge goal
select 
    l.name as league_name
    avg(m.home_goal + m.away_goal) as avg_goals,
    rank() over(order by avg(m.home_goal + m.away_goal)) as league_rank
from league as l left join match as m
on l.id = m.country_id
where season = "2013/2014"
group by l.name
order by league_rank;

select m.id, c.name as countryName, m.season, m.home_goal, m.away_goal
-- this will make aggregation over the whole dataset (all the rows of this query), since we do not use any where clause to limit it
avg(m.home_goal + m.away_goal) over() as overall_avg
from match as m left join country as c 
on m.country_id = c.id;


-- Partition by => avg(home_goal) over(partion by season)
-- find the averge for each of the seasons in this table
select
    date,
    (home_goal+away_goal) as goals,
    -- the over() period will be divided to each unique value for the season column, and we will have one avg() for each of the seasons
    avg(home_goal+away_goal) over(partition by season) s overall_avg
from match;

"""
baseballstats
---------------
Player
Team
League
BattingAvg
Hits
HomeRuns
"""
-- #1 Count() partition by players on a team
-- output: Player,Team name, total players on team in the DB
select 
    Player,
    Team,
    -- it will count how many of the players are in each team based on the table
    count(Player) over (partition by Team) as PlayerCountTeam
from baseballstats;

-- #2 show partition by AVG() batting average in the league
-- output: player, league, average batting average per league
select a.player, a.league, round(a.leagueAVG, 3) leagueAVGRounded
from (
select
    player,
    league,
    -- find the avg of leagueAVG by each league, we can't use the round() function here
    AVG(BattingAvg) over (partition by league) leagueAVG
from baseballstats) a

	
-- Sliding Windows
select 
    date, 
    home_goal, 
    away_goal, 
    -- all home goals from first row until current one sumed up
    -- track how many total goals the home team scored up to each match, in date order.
    -- sum(home_goal) => sum of home_goal values over a sliding "window" of rows
    -- over(...) => process the matches in ascending date order
    -- rows between unbounded preceding and current row => unbounded preceding: start from the very first row , current row: end at the current row => For each row, sum all previous rows including this one.
    sum(home_goal) over(order by date rows between unbounded preceding and current row) as running_total
from match
where hometeam_id = 8456 and season = '2011/2012';

-- UNBOUNDED FOLLOWING → The last row in the partition
select
    date,
    home_goal, 
    away_goal, 
    -- order by date desc => from biggest (newest) to smallest (oldest)
    -- rows between current => the window starts at the current row , and unbounded following => the window ends at the latest (last) row, it sums from the current row down to the last row
    sum(home_goal) over(order by date desc rows between current row and unbounded following) as running_total,
    avg(home_goal) over(order by date desc rows between current row and unbounded following) as running_avg
from match
where awayteam_id = 9908 and season = '2013/2014';


-- INTO
/*
The "SELECT INTO" statement allows you to create a new table and inserts data returned by a query.
The new table columns have name and data types associated with the output columns of the SELECT clause. Unlike the
SELECT statement, the SELECT INTO statement does not return data to the client.  
*/
SELECT column_list
INTO [ TEMPORARY | TEMP | UNLOGGED ] [ TABLE ] new_table_name
FROM table_name
WHERE condition;

select film_id, title, rental_rate
into table film_r
from film
where rating = 'R' and rental_duration = 5
order by title;

-- The following statement creates a temporary table named short_film that contains all films whose lengths are under 60 minutes.
select film_id, title, film_length
into temp table short_films
from film
where film_length < 60
order by title;


-- EXTENSIONS
-- shows list of all extensions available to install in postgres
select * from pg_available_extensions;

-- TRANSACTION
/*
A transaction is a unit of work that is performed against a database. Transactions are units or sequences of work accomplished in a logical order,
whether in a manual fashion by a user or automatically by some sort of a database program.
A transaction is the propagation of one or more changes to the database. For example, if you are creating a record, updating a record, or deleting a record from the table, 
then you are performing transaction on the table. It is important to control transactions to ensure data integrity and to handle database errors.

-- when we have several queries in a transaction, either they all happen or non of them happens
*/

BEGIN; -- or BEGIN TRANSACTION;
DELETE FROM company WHERE age = 25;
COMMIT; -- or END TRANSACTION;
        -- or ROLLBACK;  this one will get to situation before transaction

BEGIN;
-- Deduct 100 from account A
UPDATE accounts 
SET balance = balance - 100
WHERE account_id = 1;
-- Add 100 to account B
UPDATE accounts
SET balance = balance + 100
WHERE account_id = 2;
-- Commit the transaction
COMMIT;


-- FUNCTION | Stored Procedure
/*
functions, also known as Stored Procedures, allow you to carry out operations that would normally take several queries and round
trips in a single function within the database. Functions allow database to reuse as other applications can interact directly with your
stored procedures instead of a middle-tier or duplicating code.

There are several built-in postgres functions: Count - Max - Min - Avg - Sum - Array - Numeric
PostgreSQL ARRAY_AGG function is used to concatenate the input values including null into an array.
SELECT ARRAY_AGG(SALARY) FROM COMPANY; => {20000,15000,20000,65000,85000,45000,10000}
*/

-- Custom Function
CREATE [OR REPLACE] FUNCTION function_name (arguments)
RETURNS return_datatype AS $variable_name$
DECLARE
    declaration;
    [...]
BEGIN
    <function_body>
    [...]
    RETURN { variable_name | value }
END; 
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION totalRecords()
RETURNS integer AS $total$
DECLARE
    total INTEGER;
BEGIN
    SELECT COUNT(*) INTO total FROM company;
    RETURN total;
END;
$total$ LANGUAGE plpgsql;


-- Trigger
/* 
Triggers are database callback functions, which are automatically performed/invoked when a specified database event occurs.
triggers in SQL are spacial type of store procedures that are defined to execute automatically in place or after data modifications. it allows you
to execute a batch of code when an insert, update or any other query is executed against the table.

before insert : activated before data is inserted into the table
after insert : activated after data is inserted into the table
before update : activated before data in the table is updated
after update : activated after data in the table is updated
before delete : activated before data is removed from the table
after delete : activated after data is removed from the table

A trigger that is marked FOR EACH ROW is called once for every row that the operation modifies. In contrast, a trigger that is marked
FOR EACH STATEMENT only executes once for any given operation, regardless of how many rows it modifies.
If multiple triggers of the same kind are defined for the same event, they will be fired in alphabetical order by name.
The BEFORE, AFTER or INSTEAD OF keyword determines when the trigger actions will be executed relative to the insertion,
modification or removal of the associated row
Triggers are automatically dropped when the table that they are associated with is dropped.
event_name could be INSERT, DELETE, UPDATE, and TRUNCATE   
*/
CREATE TRIGGER trigger_name [BEFORE|AFTER|INSTEAD OF] event_name
on table_name
[
    -- Trigger logic goes here 
];

create table employees (
    id int4 serial primary key,
    first_name varchar (40) not null,
    last_name varchar (40) not null
);

create table employee_audits (
    id int4 serial primary key,
    employee_id int4 not null,
    last_name varchar (40) not null,
    changed_on timestamp (6) not null
);

-- create a trigger function:
create or replace function log_last_name_changes ()
returns trigger as $BODY$
begin
    if new.last_name <> old.last_name then
    insert into employee_audits (employee_id, last_name, changed_on) values (old.id, old.last_name, now())
    end if;
    return new;
end;
$BODY$

-- we bind the trigger function to the employees table. The trigger name is last_name_changes
create trigger last_name_changes 
	before update 
	on employees 
	for each row 
execute procedure log_last_name_changes();


-- trigger before insert
create or replace function set_invoice_total()
	return trigger 
	language plpgsql
as $$
declare 
	total int;
begin
	select sum(sI.price_in_cents) into total from cart c join shop_item as sI on sI.id = c.shop_item_id where c.user_id = new.user_id;  -- "new" here refers to the new row that is being inserted into invoice table
	new.total_in_cents := total;  -- change the value for column "total_in_cents" for the record that is being inserted into "invoice" table into total (which is 'select sum(sI.price_in_cents) from cart c join shop_item as sI on sI.id = c.shop_item_id where c.user_id = new.user_id' )
	return new;
end;
$$;

drop trigger if exists set_invoice_total_trigger on public.invoice;

create trigger set_invoice_total_trigger
	before insert
	on "invoice"
	for each row
execute procedure set_invoice_total_trigger();


-- Views
/* 
Views are pseudo-tables. That is, they are not real tables; nevertheless appear as ordinary tables to SELECT.
A view can represent a subset of a real table, selecting certain columns or certain rows from an ordinary table. A view
can even represent joined tables. Because views are assigned separate permissions, you can use them to restrict table
access so that the users see only specific rows or columns of a table.
view is a virtual table which consists of a subset of data contained in a table. since views are not present, it takes less
space to store. Views can have data of one or more tables combined and it depends on the relationship.
*/
CREATE [TEMP | TEMPORARY] VIEW view_name AS
SELECT column1, column2, ...
FROM table_name
WHERE [condition]; 

create view company_view as 
select id, name, age
from company_table;

drop view company_view;

create view V as
select ename, deptno from emp;

select * from V;

-- views can act as virtual tables, saving query data for later use
-- they can be queried like a table, but do not store data themselves

-- table employee : emp_no, birth_date, first_name, last_name, gender, hire_date
-- table dept: dept_no, dept_name
-- table dept_emp: emp_no, dept_no, from_date, to_date

create view full_emps_depts as 
select c.emp_no, first_name, last_name, gender, hire_date, dept_name
from employee e
join dept_emp c on e.emp_no = c.emp_no
join dept d on c.dept_no = d.dept_no;

show tables;  -- we can view table "full_emps_depts" now

-- we can query this view like a table
select dept_name, gender, count(*) from full_emps_depts
group by dept_name, gender;


-- dealing with ERROR | ON CONFLICT
-- if there is error for duplicate id do nothing (will skip this error):
insert into person (id, first_name, last_name, gender, email, date_of_birth, country_of_birth)
            values (18, 'Willie', 'Cherrett', 'Male', 'wcherrett0@slate.com', '2018-06-18', 'Singapore')
            on conflict (id) do nothing;

-- whenever you want to use ON CONFLICT make sure column is unique or primary key.
-- If there is a conflict of ID when inserting, do nothing except updating the email:
insert into person (id, first_name, last_name, gender, email, date_of_birth, country_of_birth)
            values (18, 'Willie', 'Cherrett', 'Male', 'wcherrett0@slate.com', '2018-06-18', 'Singapore')
            ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;

-- If there is a conflict of ID when inserting, do nothing except updating the first_name:
insert into person (id, first_name, last_name, gender, email, date_of_birth, country_of_birth)
            values (18, 'Willie', 'Cherrett', 'Male', 'wcherrett0@slate.com', '2018-06-18', 'Singapore')
            on conflict (id) do update set first_name = EXCLUDED.first_name;


-- using math in SQL
select 10^2;
select 10+2;
select 10!;  -- factorial
select 10 % 3;

SQRT(); -- square root of a number
POWER(m, n);  -- number m to the power of n

-- DATE and TIME

select NOW();  -- returns timestamp (time and date)
select NOW()::DATE; -- returns date only
select NOW()::TIME; -- returns time only

SELECT '2021-02-19'::DATE, '123'::INTEGER, 'true'::BOOLEAN, '3.14'::REAL;

select NOW() - interval '1 YEAR'; -- go back in time one year
select NOW() - interval '10 DAYS';
SELECT NOW() - interval '3 MONTHS';
select NOW() + interval '6 MONTHS';  -- go ahead 6 months ahead from now
select (NOW() + interval ' 6 MONTHS')::DATE;

select EXTRACT(YEAR FROM NOW());  -- returns only year, EXTRACT returns specific date parts (year, month, day)
select EXTRACT(CENTURY from NOW());

select first_name, last_name, AGE(NOW()::DATE, date_of_birth) AS age from person;

-- date_trunc("month", min(occurred_at)) : find the month for earliest date of a row, first occurrence
-- find all records that happened in the first month of occurance
select *
from demo.orders
where  date_trunc("month", occured_at) = (select date_trunc("month", min(occured_at)) from demo.orders)
order by occured_at;

-- INTERSECT
-- fetch common records from two tables using INTERSECT
select column1, column2 from table_1 where condition
INTERSECT
select column1, column2 from table_2 where condition;

-- only results that we get is when 'studentID' is same is 'grades' value, for example both are 20, 13,...
select studentID from students
intersect
select grades from exams

-- String Functions
-- The Postgres length() function is used to find the length of a string i.e. number of characters in the given string.
select length('w3resource') AS "length of string";

-- get first character of a string in SQL
LEFT(my_column, 1);
SUBSTRING(my_column, 1, 1)

-- add text to column's select statement
select 
    'Please try after' + CAST((1328724983-time)/60/60 as varchar(80)) AS status 
FROM 
    voting 
where 
    account = 'ThElitEyeS' and vid = 1;

-- Remove certain characters from a string

REPLACE('Your String with cityName here', 'cityName', 'xyz'); -- Results : 'Your String with xyz here'



