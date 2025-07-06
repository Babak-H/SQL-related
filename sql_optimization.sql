-- SQL Optimization

-- order to write the commands:
SELECT column1, column2, ...
FROM table_name
WHERE condition
GROUP BY column1
HAVING condition
ORDER BY column1 [ASC|DESC] ...
LIMIT number;

-- order of execution
-- 1. FROM / JOIN : specifies the tables to retrieve data from and how to join them
-- 2. WHERE : filter rows based on the condition
-- 3. GROUP BY / AGGREGATE : group rows share a property so aggregate functions can be applied
-- 4. HAVING : filter groups based on aggregate conditions (used after GROUP BY)
-- 5. SELECT : select specific columns to display in the final results
-- 6. DISTINCT : remove duplicate rows from the result set (applied after SELECT)
-- 7. ORDER BY : sorts the result set based on the specific columns/values
-- 8. LIMIT / OFFSET : limits the number of rows returned, often used for pagination


-- for optimizations we reduce the amount of calculations that a query needs to perform
-- the bigger the table size, the slower the query
-- joins between tables slows down queries
-- aggregation functions slow down queries
-- 'distinct count()' is significantly slower than 'count()' since it has to compare all rows to find unique ones.

-- option1 : filtering the data to only include the rows that you actually need
-- if you have a big dataset, do explarotary queires on a small portion, then do the final query on the whole dataset

select *
from demo.orders
where occured_at >= '2016-01-01' and occured_at < '2016-05-31'

-- here the limit part is "useless" as LIMIT CLAUSE RUNS AFTER SUM() AGGREGATION
select sum(poster_qty) as sum_poster_qty
from demo orders
where occured_at >= '2016-01-01' and occured_at < '2016-05-31'
group by 1
limit 10;

-- instead of limit, get data from a limited subquery
select sum(poster_qty) as sum_poster_qty
from (select * from demo.orders limit 10) as sub
where occured_at >= '2016-01-01' and occured_at < '2016-05-31'
group by 1;  -- group by first column


-- option2 : reduce number of rows evaluated during join (make it less complicated)
select accounts.name, count(*) as web_events
from demo.accounts accounts
join demo.web_events_full events
on events.account_id = accounts.id
order by 1 -- order by first column (accounts.name)
group by 2; -- group by second column (web_events)

-- improve it by aggregating the second table before the join (use subquery), makes the join process much faster since second table becomes smaller
-- since join happens Before group by
select a.name, sub.web_events
from (select account_id, count(*) as web_events from demo.web_events_full group by 1) sub
join demo.accounts a
on a.id = sub.account_id
order by 2;


-- option3 : adding EXPLAIN to start of query shows how it is executed
explain
select * 
from demo.orders
where occured_at >= '2016-01-01' and occured_at < '2016-05-31';


-- execution plan in SQL
/* An execution plan is basically a road map that graphically or textually shows the data retrieval methods chosen by the 
SQL server’s query optimizer for a stored procedure or ad hoc query. Execution plans are very useful for helping a 
developer understand and analyze the performance characteristics of a query or stored procedure */


-- ACID concepts
-- Atomicity, Consistency, Isolation, Durability
/*
Atomicity => Atomicity requires that each transaction be “all or nothing”: if one part of the transaction fails, the 
entire transaction fails, and the database state is left unchanged. An atomic system must guarantee atomicity in each 
and every situation, including power failures, errors, and crashes.

Consistency => The consistency property ensures that any transaction will bring the database from one valid state to 
another. Any data written to the database must be valid according to all defined rules, including constraints, cascades, 
triggers, and any combination thereof.

Isolation => The isolation property ensures that the concurrent execution of transactions results in a system state that 
would be obtained if transactions were executed serially, i.e., one after the other. Providing isolation is the main goal
of concurrency control. Depending on concurrency control method (i.e. if it uses strict - as opposed to relaxed - serializability), 
the effects of an incomplete transaction might not even be visible to another transaction.

Durability => Durability means that once a transaction has been committed, it will remain so, even in the event of power 
loss, crashes, or errors. In a relational database, for instance, once a group of SQL statements execute, the results 
need to be stored permanently (even if the database crashes immediately thereafter). To defend against power loss, 
transactions (or their effects) must be recorded in a non-volatile memory. */


-- What is the difference between the WHERE and HAVING clauses?
/*
When GROUP BY is not used, the WHERE and HAVING clauses are essentially equivalent
However, when GROUP BY is used:
The WHERE clause is used to filter records from a result. The filtering occurs BEFORE any groupings are made.
The HAVING clause is used to filter values from a group (so AFTER group by)
(i.e., to check conditions after aggregation into groups has been performed). */

-- Varchar vs Char
/*
When stored in a database, varchar uses only the allocated space. E.g. if you have a varchar(1999) and put 50 bytes 
in the table, it will use 52 bytes.
But when stored in a database, char always uses the maximum length and is blank-padded. E.g. if you have char(1999) 
and put 50 bytes in the table, it will consume 2000 bytes.
*/

-- join with one-to-many relationship
/* A LEFT JOIN without GROUP BY in a one-to-many relationship will result in duplicate rows for each match on the "many" side. If there are no matches, 
the row from the "one" side will still appear with NULLs for the "many" side columns. */


-- database denormalization
/* denormalization is a method to improve the performance of database, allowing quicker retrieval of data.
in this proccess we add up several smaller tables and make a bigger table, making it faster to query without join. */

-- write a query to count the number of 'unique users per day' who logged in 'from both iphone and web' where 'iphone and web logs are in distinct relation'.

-- iphone: timestamp | user_id | iphone_session_id
-- web:    timestamp | user_id | web_session_id

-- 1) join
-- 2) match by day and user_id
-- 3) group by day and count num_users

select
    date_trunc('day', i.timestamp) as day,
    count(distinct i.user_id) as num_users
from iphone i join web w
-- join on being same user and same day
on i.user_id = w.user_id and date_trunc('day', i.timestamp) = date_trunc('day', w.timestamp)
group by 1; -- group by each day in table


-- display Nth row of a table/query:
-- way 1:
select * from emp limit 4
except 
select * from emp limit 3;
-- way 2:
-- select id, emp.* from emp => here we will have two ID columns in our rows
select * from (select emp.* from emp) where id = 4;

-- Find Nth highest value from a table:
select min(salary) as tenthHighestSalary from (
    select distinct salary from employee order by salary desc limit 10
) as emp;
-- another way:
select distinct salary from employee order by salary desc limit 1 offset 9;

-- given the following tables what will be the result of query below?
sql> select * from runners;
+----+--------------+
| id | name         |
+----+--------------+
|  1 | John Doe     |
|  2 | Jane Doe     |
|  3 | Alice Jones  |
|  4 | Bobby Louis  |
|  5 | Lisa Romero  |
+----+--------------+

sql> select * from races;
+----+----------------+-----------+
| id | event          | winner_id |
+----+----------------+-----------+
|  1 | 100 meter dash |  2        |
|  2 | 500 meter dash |  3        |
|  3 | cross-country  |  2        |
|  4 | triathalon     |  NULL     |
+----+----------------+-----------+

select * from runners where id not in (select winner_id from races);
-- If the set being evaluated by the SQL NOT IN condition contains any values that are null, then the outer query here will return an empty set.
-- to fix such issues:
select * from runners where id not in (select winner_id from races where winner_id is not null);

-- Assume a schema of Emp( Id, Name, DeptId ) , Dept ( Id, Name). If there are 10 records in the Emp table and 5 records 
-- in the Dept table, how many rows will be displayed in the result of the following SQL query:
select * from Emp, Dept;
-- The query will result in 50 rows as a “cartesian product” or “cross join”, which is the default whenever the ‘where’ clause is omitted.

-- Write a query to fetch values in table 'test_a' that are and not in table 'test_b' without using the NOT keyword.
create table test_a(id numeric);
create table test_b(id numeric);

insert into test_a(id) values (10), (20), (30), (40), (50);
insert into test_b(id) values (10), (30), (50);
-- answer:
select * from test_a except select * from test_b;

-- given the following tables:
SELECT * FROM users;
/*
user_id  username
1        John Doe                                                                                            
2        Jane Don                                                                                            
3        Alice Jones                                                                                         
4        Lisa Romero
*/

SELECT * FROM training_details;
/*
user_training_id  user_id  training_id  training_date
1                 1        1            "2015-08-02"
2                 2        1            "2015-08-03"
3                 3        2            "2015-08-02"
4                 4        2            "2015-08-04"
5                 2        2            "2015-08-03"
6                 1        1            "2015-08-02"
7                 3        2            "2015-08-04"
8                 4        3            "2015-08-03"
*/
--- Write a query to to get the list of users who took the a training lesson more than once in the same 
-- day, grouped by user and training lesson, each ordered from the most recent lesson date to oldest date.
SELECT 
    u.user_id, 
    username, 
    training_id, 
    training_date, 
    COUNT(user_training_id) AS count
FROM users u 
JOIN training_details t ON t.user_id = u.user_id
-- The GROUP BY clause is grouping rows by all four columns together, Every unique combination of those four values becomes one group
-- The COUNT(user_training_id) counts how many records fall into each of these unique groups
GROUP BY u.user_id, username, training_id, training_date
HAVING COUNT(user_training_id) > 1
ORDER BY training_date DESC;

-- Given a table dbo.users where the column user_id is a unique numeric identifier, how can you efficiently select the 
-- first 100 odd (1,3,5,..) user_id values from the table? (Assume the table contains well over 100 records with odd user_id values.)
SELECT user_id 
FROM dbo.users 
WHERE user_id % 2 = 1 
ORDER BY user_id
LIMIT 100;

-- Given a table employee having columns empName and empId, what will be the result of the SQL query below?
select empName from employee order by 2 desc; 
-- it will throw an error, because even though the table has 2 columns, here we only selected on of them.

-- The invoices table contains the reference number and due dates of invoices. After some negotiations, it was agreed 
-- that all the due dates can be shifted by 90 days. Determine the new due dates.
-- INTERVAL is used to add a time duration to a date or timestamp
select reference, due_date + interval '90 days' as new_date
from invoices
order by new_date, reference;

-- Extract the name of artists that start with a vowel ('A', 'E', 'I', 'O', 'U'). No duplicates.
select distinct a_name
from artists 
where left(name, 1) in ('A', 'E', 'I', 'O', 'U')
order by name
limit 10;

-- How many missing values are in the price column of the wine table?
select count(*)
from wine
where price is null;

-- case 
SELECT ename, sal,
    CASE WHEN sal <= 2000 THEN 'underpaid'
         WHEN sal >= 4000 THEN 'overpaid'
         ELSE 'ok'
    END AS sal_lvl  -- name of new column alias is sal_lvl
FROM emp;

-- The songs table shows id of a song, the name of the song, the observed date, and the number of times it has been 
-- played as playbacks in millions per year. A preview of the songs table is shown.
-- Determine the total number of playbacks per year and compare that to the all time number of playbacks.
/*

*/
select 
    date_part('year', date_observed) as yearly,
    -- total playback of all songs added together in a year
    sum(playbacks) as yearly_playbacks,
    -- here we use subquery, since it won't be affected by the group by
    (select sum(playbacks) from songs) as total_playbacks
from songs
group by yearly
order by yearly
limit 10;

-- The tracks table contains information on a variety of tracks, including the artist_id and song popularity.
-- Return the artist_id and average song popularity for artists who have an average song popularity greater than 50.
/* 
tracks
id       name                    artist_id      popularity           

3qyX4g  Soon We'll Be Found     5WUlDf          35       
04sN26  Bored                   6qqNVT          77       
4cCXPF  On Top Of The World     53Xhwf          1        
*/
select artist_id, avg(popularity)
from tracks
group by artist_id
-- when using groupby aggregation, use HAVING instead of WHERE, since WHERE is executed before GROUP BY
-- avg for popularity of all songs that belong to an artist
having avg(popularity) > 50
order by artist_id
limit 5;

-- Using the artists and tracks tables, return the name of every artist and the count of songs they perform from the tracks table.
/*
artists
| id     | followers | name          | popularity |
|--------|-----------|---------------|------------|
| 1uNFoZ | 44606973  | Justin Bieber | 100        |
| 06HL4z | 38869193  | Taylor Swift  | 98         |
| 3TVXtA | 54416812  | Drake         | 98         |

tracks
| id     | name                | artist_id | release_date |
|--------|---------------------|-----------|--------------|
| 3qyX4g | Soon We'll Be Found | 5WUlDf    | 2004-10-03   |
| 04sN26 | Bored               | 6qqNVT    | 2017-03-30   |
| 4cCXPF | On Top Of The World | 53Xhwf    | 2021-04-09   |
*/
select artist.name as artist_name, count(tracks.name)
-- we left join from tracks to artists, because many tracks can have one artist, and we do not want duplicate rows here
from tracks left join artists
on tracks.artist_id = artist.id
group by artists.name  -- groupby name of the artist, since we will aggregate it with COUNT(tracks.name) function
order by count(*) desc
limit 10;

/* given a table of job postings, write a query to breakdown the number of users that have posted their jobs once
versus number of users that have posted at least one job several times.

'job_postings'
col            type
---------------------
id             integer
job_id         integer
user_id        integer
date_posted    datetime
*/
-- Counts how many times each user posted a given job (on different dates)
WITH user_job AS (
    SELECT user_id, job_id, COUNT(DISTINCT date_posted) AS num_posted
    FROM job_postings
    GROUP BY user_id, job_id
),
-- Flags users who posted any job more than once
user_flags AS (
    SELECT 
        user_id,
        MAX(CASE WHEN num_posted > 1 THEN 1 ELSE 0 END) AS has_repeat_post
    FROM user_job
    GROUP BY user_id
)
-- Counts users by flag, how many users have posted more than once, how many users have posted only once
SELECT
    SUM(CASE WHEN has_repeat_post = 1 THEN 1 ELSE 0 END) AS posted_several_times,
    SUM(CASE WHEN has_repeat_post = 0 THEN 1 ELSE 0 END) AS posted_once
FROM user_flags;


-- Select matches where Barcelona was the away team
select 
    m.date,
    t.team_long_name as opponent,  -- opponent here means the team that is playing in their home stadium
    case when m.home_goal < m.away_goal then 'Barcelona win'
         when m.home_goal > m.away_goal then 'Barcelona loss'
         else 'tie' end as outcome
from matches_spain as m
left join teams_spain as t
on m.home_team_id = t.team_api_id  -- make sure the team actually exists and is not wrong team name
where m.awayteam_id = 8634;  -- after join, filter that only the away_team is Barcelona


-- Sum the total records in each season where the home team won in each country
select c.name as country,
       sum(case when m.season = '2012/2013' and m.home_goal > m.away_goal then 1 else 0 end) as matches_2012_2013,
       sum(case when m.season = '2013/2014' and m.home_goal > m.away_goal then 1 else 0 end) as matches_2013_2014,
       sum(case when m.season = '2014/2015' and m.home_goal > m.away_goal then 1 else 0 end) as matches_2014_2015
from country as c
join match as m
on c.id = m.country_id
group by country;

-- another way to get the same results
select 
    c.name as country,
    m.season,
    count(*) as home_wins
FROM country c
join match m on c.id = m.country_id
where m.home_goal > m.away_goal  -- make this global instead of inside case statement
group by country, m.season;  -- group by combination of country and season


-- how many matches happened per season, country where there was > 5 goals by a team
select
    country_id,
    season,
    count(id) as matches
from (select country_id, season, id from match where home_goal >= 5 or away_goal >= 5) sub
group by country_id, season;  -- group by combination of country and season