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


/*
given a table salary, such as the one below, that m=male and f=female, swap all f and m values
with "a single update statement" and no intermediate temp table.

id      name    sex     salary
1       A       m       2500
2       B       f       1500
3       C       f       5500
4       D       m       800

after running the query it should look like this:

id      name    sex     salary
1       A       f       2500
2       B       m       1500
3       C       m       5500
4       D       f       800
*/
UPDATE salary
SET sex = CASE
             WHEN sex = 'f' THEN 'm'
             ELSE 'f'
          END;

/*
X city has opened a new cinema, many people would like to go to this cinema. the cinema also gives out a poster
indicating the movie rating and description. write a sql query to output movies with odd numbered ID and a description
that is not 'boring'.

Cinema table:
+----+------------+-------------+--------+
| id | movie      | description | rating |
+----+------------+-------------+--------+
| 1  | War        | great 3D    | 8.9    |
| 2  | Science    | fiction     | 8.5    |
| 3  | irish      | boring      | 6.2    |
| 4  | Ice song   | Fantacy     | 8.6    |
| 5  | House card | Interesting | 9.1    |
+----+------------+-------------+--------+

output should be:
+----+------------+-------------+--------+
| id | movie      | description | rating |
+----+------------+-------------+--------+
| 5  | House card | Interesting | 9.1    |
| 1  | War        | great 3D    | 8.9    |
+----+------------+-------------+--------+

Explanation: 
We have three movies with odd-numbered IDs: 1, 3, and 5. The movie with ID = 3 is boring so we do not include it in the answer.
*/
SELECT *
FROM cinema
WHERE id%2 != 0
AND description <> 'boring'
ORDER BY rating DESC;


/*
the Employee table holds records for all employees (including managers), find all employees that earn more than their manager.

Employee table:
+----+-------+--------+-----------+
| id | name  | salary | managerId |
+----+-------+--------+-----------+
| 1  | Joe   | 70000  | 3         |
| 2  | Henry | 80000  | 4         |
| 3  | Sam   | 60000  | Null      |
| 4  | Max   | 90000  | Null      |
+----+-------+--------+-----------+
*/
SELECT a.name as employee
FROM Employee a
JOIN Employee b
ON a.managerId = b.id
WHERE a.salary > b.salary;


/*
write a SQL query to find all duplicate emails in a table named Person

Person table:
+----+---------+
| id | email   |
+----+---------+
| 1  | a@b.com |
| 2  | c@d.com |
| 3  | a@b.com |
+----+---------+
*/
SELECT email
FROM Person
GROUP BY email
HAVING COUNT(email) > 1;  -- where filters rows Before grouping, having does it After


/*
Write a solution to report the first name, last name, city, and state of each person in the Person table. If the address of a personId is not present in the Address table, report null instead.

Person table:
+----------+----------+-----------+
| personId | lastName | firstName |
+----------+----------+-----------+
| 1        | Wang     | Allen     |
| 2        | Alice    | Bob       |
+----------+----------+-----------+

Address table:
+-----------+----------+---------------+------------+
| addressId | personId | city          | state      |
+-----------+----------+---------------+------------+
| 1         | 2        | New York City | New York   |
| 2         | 3        | Leetcode      | California |
+-----------+----------+---------------+------------+

Output: 
+-----------+----------+---------------+----------+
| firstName | lastName | city          | state    |
+-----------+----------+---------------+----------+
| Allen     | Wang     | Null          | Null     |
| Bob       | Alice    | New York City | New York |
+-----------+----------+---------------+----------+
*/
SELECT p.firstName, p.lastName, a.city, a.state
FROM Person p 
LEFT JOIN Address a
ON p.personId = a.personId;


/*
Write a solution to find the rank of the scores. The ranking should be calculated according to the following rules:

The scores should be ranked from the highest to the lowest.
If there is a tie between two scores, both should have the same ranking.
After a tie, the next ranking number should be the next consecutive integer value. In other words, there should be no holes between ranks.
Return the result table ordered by score in descending order.
 
Scores table:
+----+-------+
| id | score |
+----+-------+
| 1  | 3.50  |
| 2  | 3.65  |
| 3  | 4.00  |
| 4  | 3.85  |
| 5  | 4.00  |
| 6  | 3.65  |
+----+-------+
Output: 
+-------+------+
| score | rank |
+-------+------+
| 4.00  | 1    |
| 4.00  | 1    |
| 3.85  | 2    |
| 3.65  | 3    |
| 3.65  | 3    |
| 3.50  | 4    |
+-------+------+

SQL has a built-in function called DENSE_RANK(), It ranks items without skipping numbers when there's a tie
DENSE_RANK() OVER(ORDER BY score DESC)
This will assign rank 1 to the highest score, If two scores are tied, they both get the same rank, he next different score gets the next immediate rank, not a skipped one.
*/
SELECT score, 
       DENSE_RANK() OVER(ORDER BY score DESC) as rank
FROM Scores;


/*
Write a solution to find employees who have the highest salary in each of the departments. Return the result table in any order.

Employee table:
+----+-------+--------+--------------+
| id | name  | salary | departmentId |
+----+-------+--------+--------------+
| 1  | Joe   | 70000  | 1            |
| 2  | Jim   | 90000  | 1            |
| 3  | Henry | 80000  | 2            |
| 4  | Sam   | 60000  | 2            |
| 5  | Max   | 90000  | 1            |
+----+-------+--------+--------------+

Department table:
+----+-------+
| id | name  |
+----+-------+
| 1  | IT    |
| 2  | Sales |
+----+-------+

Output: 
+------------+----------+--------+
| Department | Employee | Salary |
+------------+----------+--------+
| IT         | Jim      | 90000  |
| Sales      | Henry    | 80000  |
| IT         | Max      | 90000  |
+------------+----------+--------+
Max and Jim both have the highest salary in the IT department and Henry has the highest salary in the Sales department
*/

-- we need to have DENSE_RANK as here we have both Jim and Max in the table (both have same salary)
-- there should be join between Employee and Department tables
-- we use CTE instead of subquery to make the code less complicated

-- DENSE_RANK() => This function assigns ranking numbers to rows without gaps, even if there's a tie
-- PARTITION BY departmentId => like grouping" the data, but without collapsing it into fewer rows, It means: for each department, apply the ranking logic independently.
-- ORDER BY salary DESC => Within each department group, order the employees by salary in descending order (highest first), rank is assigned based on this order
WITH RankedSalaries AS (
    SELECT 
        departmentId, 
        name AS employee, 
        salary,
        DENSE_RANK() OVER(PARTITION BY departmentId ORDER BY salary DESC) AS denseRank
    FROM Employee
)
-- For each departmentId, rank the employees based on their salary from highest to lowest. If multiple employees have the same salary, give them the same rank, and don’t skip numbers
SELECT 
    d.name AS Department, 
    r.employee AS Employee, 
    r.salary AS Salary
FROM RankedSalaries r
JOIN Department d ON r.departmentId = d.id
-- This filters the results to include only the employees who have the highest salary within their department.
-- the employee(s) with the highest salary in each department got denseRank = 1
WHERE r.denseRank = 1
ORDER BY d.name ASC;


/*
Find Followers Count. Write a solution that will, for each user, return the number of followers, Return the result table ordered by user_id in ascending order.

Followers table:
+---------+-------------+
| user_id | follower_id |
+---------+-------------+
| 0       | 1           |
| 1       | 0           |
| 2       | 0           |
| 2       | 1           |
+---------+-------------+

Output: 
+---------+----------------+
| user_id | followers_count|
+---------+----------------+
| 0       | 1              |
| 1       | 1              |
| 2       | 2              |
+---------+----------------+

The followers of 0 are {1}
The followers of 1 are {0}
The followers of 2 are {0,1}
*/
SELECT user_id, COUNT(follower_id) AS followers_count
FROM Followers
GROUP BY user_id
ORDER BY user_id ASC;


/*
Write an SQL query to show the "second most recent activity of each user". If the user only has one activity, return that one. 
A user can't perform more than one activity at the same time. Return the result table in any order.

UserActivity:
+------------+--------------+-------------+-------------+
| username   | activity     | startDate   | endDate     |
+------------+--------------+-------------+-------------+
| Alice      | Travel       | 2020-02-12  | 2020-02-20  |
| Alice      | Dancing      | 2020-02-21  | 2020-02-23  |
| Alice      | Travel       | 2020-02-24  | 2020-02-28  |
| Bob        | Travel       | 2020-02-11  | 2020-02-18  |
+------------+--------------+-------------+-------------+

Result:
+------------+--------------+-------------+-------------+
| username   | activity     | startDate   | endDate     |
+------------+--------------+-------------+-------------+
| Alice      | Dancing      | 2020-02-21  | 2020-02-23  |
| Bob        | Travel       | 2020-02-11  | 2020-02-18  |
+------------+--------------+-------------+-------------+

The most recent activity of Alice is Travel from 2020-02-24 to 2020-02-28, before that she was dancing from 2020-02-21 to 2020-02-23.
Bob only has one record, we just take that one.
*/
SELECT username, activity, startDate, endDate FROM
-- we create subquery lookup and get some of the columns from it
(SELECT username, activity, startDate, endDate,
-- we rank all activity for each username based on when the activity ended ordered by the one finished the latest
RANK() OVER(PARTITION BY username ORDER BY endDate DESC) r,
-- we also get count of how many activities a user did based on its username
COUNT(activity) OVER(PARTITION BY username) c
FROM UserActivity) lookup
-- r=2 => give us the second rank from subquery column r => second most recent activity of each user
-- OR 
-- c=1 => If the user only has one activity, return that one
WHERE r = 2 OR c = 1;

/*
Table: Accounts

+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| id            | int     |
| name          | varchar |
+---------------+---------+
id is the primary key for this table.
This table contains the account id and the user name of each account.

Table: Logins

+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| id            | int     |
| login_date    | date    |
+---------------+---------+
There is no primary key for this table, it may contain duplicates.
This table contains the account id of the user who logged in and the login date. A user may log in multiple times in the day.

Active users are those who logged in to their accounts for five or more consecutive days.
Write an SQL query to find the id and the name of active users, Return the result table ordered by id.

Input: 
Accounts table:
+----+----------+
| id | name     |
+----+----------+
| 1  | Winston  |
| 7  | Jonathan |
+----+----------+
Logins table:
+----+------------+
| id | login_date |
+----+------------+
| 7  | 2020-05-30 |
| 1  | 2020-05-30 |
| 7  | 2020-05-31 |
| 7  | 2020-06-01 |
| 7  | 2020-06-02 |
| 7  | 2020-06-02 |
| 7  | 2020-06-03 |
| 1  | 2020-06-07 |
| 7  | 2020-06-10 |
+----+------------+
Output: 
+----+----------+
| id | name     |
+----+----------+
| 7  | Jonathan |
+----+----------+
*/

-- when we want to compare two rows in the same table, we can use a self-join to connect them together
-- we need to have 5 login records for an specific id in a row during 5 consecutive days.

select distinct a.id, Accounts.name from Logins a join Logins b
on a.id = b.id and datediff(a.login_date, b.login_date) between 1 and 4
joins Accounts pn a.id = Accounts.id
-- we group by a.date, since we need to use b.login_date with COUNT function.
group by a.id, a.login_date
-- we use distinct login since user might login several times per day
having count(distinct b.login_date) = 4;


-- cities with most expensive homes
-- write a query to identify cities with higher than national average home prices, output by city name
/*
TABLE:
id
state
city
street
mkt_price
*/

-- step 1
select AVG(mkt_price) from z_housing;

-- step 2
select city, AVG(mkt_price)
from z_housing
group by city;

-- final query, where average of the price in city, is higher than average for entire table (country)
select city
from z_housing
having AVG(mkt_price) > 
(select AVG(MKT_price) from z_housing);


-- department with highest salary

select department.name as Department, employee.name as Employee, employee.salary as Salary
from employee join department 
on employee.departmentid = department.id
where (departmentid, salary) in  -- this way even if two employees have the same max salary, we still get both
(select departmentid, max(salary) from employee group by departmentid)


/*
+----------------+---------+
| Column Name    | Type    |
+----------------+---------+
| machine_id     | int     |
| process_id     | int     |
| activity_type  | enum    |
| timestamp      | float   |
+----------------+---------+

machine_id is the ID of a machine.
process_id is the ID of a process running on the machine with ID machine_id.
activity_type is an ENUM (category) of type ('start', 'end').
timestamp is a float representing the current time in seconds.
'start' means the machine starts the process at the given timestamp and 'end' means the machine ends the process at the given timestamp.
The 'start' timestamp will always be before the 'end' timestamp for every (machine_id, process_id) pair.
It is guaranteed that each (machine_id, process_id) pair has a 'start' and 'end' timestamp.

There is a factory website that has several machines each running the same number of processes. Write a solution to find the average time each machine takes to complete a process.
The time to complete a process is the 'end' timestamp minus the 'start' timestamp. The average time is calculated by the total time to complete every process on the machine divided by the number of processes that were run.

Activity table:
+------------+------------+---------------+-----------+
| machine_id | process_id | activity_type | timestamp |
+------------+------------+---------------+-----------+
| 0          | 0          | start         | 0.712     |
| 0          | 0          | end           | 1.520     |
| 0          | 1          | start         | 3.140     |
| 0          | 1          | end           | 4.120     |
| 1          | 0          | start         | 0.550     |
| 1          | 0          | end           | 1.550     |
| 1          | 1          | start         | 0.430     |
| 1          | 1          | end           | 1.420     |
| 2          | 0          | start         | 4.100     |
| 2          | 0          | end           | 4.512     |
| 2          | 1          | start         | 2.500     |
| 2          | 1          | end           | 5.000     |
+------------+------------+---------------+-----------+
*/

select machine_id, round(avg(b.timestamp - a.timestamp), 3) as processing_time
from Acticvity a join Activity b on a.machine_id = b.machine_id and a.process_id = b.process_id
where a.activity_type = "start" and b.activity_type = "end"
group by machine_id;


/*
Table: Seat
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| student     | varchar |
+-------------+---------+

If the number of students is odd, the id of the last student is not swapped.
Return the result table ordered by id in ascending order.
The result format is in the following example.
Example 1:

Input:
| id          | int     |
| student     | varchar |
+-------------+---------+

Write a solution to swap the seat id of every two consecutive students. If the number of students is odd, the id of the last student is not swapped.
Return the result table ordered by id in ascending order.
The result format is in the following example.
Example 1:

Input: 
Seat table:
+----+---------+
| id | student |
+----+---------+
| 1  | Abbot   |
| 2  | Doris   |
| 3  | Emerson |
| 4  | Green   |
| 5  | Jeames  |
+----+---------+
Output: 
+----+---------+
| id | student |
+----+---------+
| 1  | Doris   |
| 2  | Abbot   |
| 3  | Green   |
| 4  | Emerson |
| 5  | Jeames  |
+----+---------+
Explanation: 
Note that if the number of students is odd, there is no need to change the last one's seat.
*/

select IF(id < (select max(id) from seat), if(id % 2 = 0, id-1, id+1), if(id % 2 = 0, id-1, id)) as id,
student  from seat
order by id;


/*
Table: Customers
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| name        | varchar |
+-------------+---------+

Table: Orders
+-------------+------+
| Column Name | Type |
+-------------+------+
| id          | int  |
| customerId  | int  |
+-------------+------+
customerId is a foreign key (reference columns) of the ID from the Customers table.
Each row of this table indicates the ID of an order and the ID of the customer who ordered it.

Write a solution to find all customers who never order anything.
Return the result table in any order.
The result format is in the following example.

Input: 
Customers table:
+----+-------+
| id | name  |
+----+-------+
| 1  | Joe   |
| 2  | Henry |
| 3  | Sam   |
| 4  | Max   |
+----+-------+
Orders table:
+----+------------+
| id | customerId |
+----+------------+
| 1  | 3          |
| 2  | 1          |
+----+------------+
Output: 
+-----------+
| Customers |
+-----------+
| Henry     |
| Max       |
+-----------+
*/

select name as Customers 
from Customers left join Orders on Customers.id = Orders.customerId
where customerId is null;

-- second approach
select name as Customers
from Customers
where id not in (select customerId from Orders);


/*
Table: Person

+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| email       | varchar |
+-------------+---------+
id is the primary key (column with unique values) for this table.
Each row of this table contains an email. The emails will not contain uppercase letters.

Write a solution to report all the duplicate emails. Note that it's guaranteed that the email field is not NULL.
Return the result table in any order.
The result format is in the following example.

Input: 
Person table:
+----+---------+
| id | email   |
+----+---------+
| 1  | a@b.com |
| 2  | c@d.com |
| 3  | a@b.com |
+----+---------+
Output: 
+---------+
| Email   |
+---------+
| a@b.com |
+---------+
Explanation: a@b.com is repeated two times.
*/

select email from
(select email, count(email) as c from person group by email) as temp
where c > 1;

-- second approach
select email from
from person
group by email
having count(email) > 1;


/*
Table: Products
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| product_id  | int     |
| low_fats    | enum    |
| recyclable  | enum    |
+-------------+---------+

low_fats is an ENUM (category) of type ('Y', 'N') 
recyclable is an ENUM (category) of types ('Y', 'N') 
Write a solution to find the ids of products that are both low fat and recyclable.

Input: 
Products table:
+-------------+----------+------------+
| product_id  | low_fats | recyclable |
+-------------+----------+------------+
| 0           | Y        | N          |
| 1           | Y        | Y          |
| 2           | N        | Y          |
| 3           | Y        | Y          |
| 4           | N        | N          |
+-------------+----------+------------+
Output: 
+-------------+
| product_id  |
+-------------+
| 1           |
| 3           |
+-------------+
*/

select product_id from Products 
where low_fats = 'Y' and recyclable = 'Y';


/*
Table: Scores

+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| score       | decimal |
+-------------+---------+
id is the primary key
Each row of this table contains the score of a game
 
Write a solution to find the rank of the scores:
The scores should be ranked from the highest to the lowest.
If there is a tie between two scores, both should have the same ranking.
After a tie, the next ranking number should be the next consecutive integer value. In other words, there should be no holes between ranks.

Input: 
Scores table:
+----+-------+
| id | score |
+----+-------+
| 1  | 3.50  |
| 2  | 3.65  |
| 3  | 4.00  |
| 4  | 3.85  |
| 5  | 4.00  |
| 6  | 3.65  |
+----+-------+
Output: 
+-------+------+
| score | rank |
+-------+------+
| 4.00  | 1    |
| 4.00  | 1    |
| 3.85  | 2    |
| 3.65  | 3    |
| 3.65  | 3    |
| 3.50  | 4    |
+-------+------+
*/

select 
    score, 
    -- use ranking over the the score window partition
    dense_rank() over (order by score desc) as "Rank" -- we use dense_rank() because we want to avoid gaps in the ranks
from Scores;


/*
Nth Highest Salary

+-------------+------+
| Column Name | Type |
+-------------+------+
| id          | int  |
| salary      | int  |
+-------------+------+
id is the primary key 
Each row of this table contains information about the salary of an employee.
Write a solution to find the nth highest distinct salary from the Employee table. If there are less than n distinct salaries, return null.

Input: 
Employee table:
+----+--------+
| id | salary |
+----+--------+
| 1  | 100    |
| 2  | 200    |
| 3  | 300    |
+----+--------+
n = 2
Output: 
+------------------------+
| getNthHighestSalary(2) |
+------------------------+
| 200                    |
+------------------------+

Input: 
Employee table:
+----+--------+
| id | salary |
+----+--------+
| 1  | 100    |
+----+--------+
n = 2
Output: 
+------------------------+
| getNthHighestSalary(2) |
+------------------------+
| null                   |
+------------------------+
*/

select distinct salary 
from Employee
order by salary desc
limit 1 offset n-1;


/*
Table: Person
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| personId    | int     |
| lastName    | varchar |
| firstName   | varchar |
+-------------+---------+

Table: Address
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| addressId   | int     |
| personId    | int     |
| city        | varchar |
| state       | varchar |
+-------------+---------+
Each row of this table contains information about the city and state of one person with ID = PersonId.
Write a solution to report the first name, last name, city, and state of each person in the Person table. If the address of a personId is not present in the Address table, report null instead.

Input: 
Person table:
+----------+----------+-----------+
| personId | lastName | firstName |
+----------+----------+-----------+
| 1        | Wang     | Allen     |
| 2        | Alice    | Bob       |
+----------+----------+-----------+
Address table:
+-----------+----------+---------------+------------+
| addressId | personId | city          | state      |
+-----------+----------+---------------+------------+
| 1         | 2        | New York City | New York   |
| 2         | 3        | Leetcode      | California |
+-----------+----------+---------------+------------+
Output: 
+-----------+----------+---------------+----------+
| firstName | lastName | city          | state    |
+-----------+----------+---------------+----------+
| Allen     | Wang     | Null          | Null     |
| Bob       | Alice    | New York City | New York |
+-----------+----------+---------------+----------+
Explanation: 
There is no address in the address table for the personId = 1 so we return null in their city and state.
addressId = 1 contains information about the address of personId = 2.
*/

select firstName, lastName, city, state
from Person left join Address on Person.personId = Address.personId;


/*
Table: Person

+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| email       | varchar |
+-------------+---------+

Write a solution to delete all duplicate emails, keeping only one unique email with the smallest id.

Input: 
Person table:
+----+------------------+
| id | email            |
+----+------------------+
| 1  | john@example.com |
| 2  | bob@example.com  |
| 3  | john@example.com |
+----+------------------+
Output: 
+----+------------------+
| id | email            |
+----+------------------+
| 1  | john@example.com |
| 2  | bob@example.com  |
+----+------------------+
*/

delete p2 
from person p1 join person p2
on p1.email = p2.email
and p1.id < p2.id;  -- we keep first record with the smallest id


/*
Table: Employee
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| name        | varchar |
| salary      | int     |
| managerId   | int     |
+-------------+---------+

Write a solution to find the employees who earn more than their managers.

Input: 
Employee table:
+----+-------+--------+-----------+
| id | name  | salary | managerId |
+----+-------+--------+-----------+
| 1  | Joe   | 70000  | 3         |
| 2  | Henry | 80000  | 4         |
| 3  | Sam   | 60000  | Null      |
| 4  | Max   | 90000  | Null      |
+----+-------+--------+-----------+
Output: 
+----------+
| Employee |
+----------+
| Joe      |
+----------+
Explanation: Joe is the only employee who earns more than his manager.
*/

select e1.name as Employee
from employee e1 join employee e2
on e1.managerId = e2.id
where e1.salary > e2.salary;


/*
Table: Employee
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| id           | int     |
| name         | varchar |
| salary       | int     |
| departmentId | int     |
+--------------+---------+
departmentId is a foreign key (reference column) of the ID from the Department table.
 
Table: Department
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| name        | varchar |
+-------------+---------+

A company's executives are interested in seeing who earns the most money in each of the company's departments. A high earner in a department is an employee who has 
a salary in the top three unique salaries for that department. Write a solution to find the employees who are high earners in each of the departments.

Input: 
Employee table:
+----+-------+--------+--------------+
| id | name  | salary | departmentId |
+----+-------+--------+--------------+
| 1  | Joe   | 85000  | 1            |
| 2  | Henry | 80000  | 2            |
| 3  | Sam   | 60000  | 2            |
| 4  | Max   | 90000  | 1            |
| 5  | Janet | 69000  | 1            |
| 6  | Randy | 85000  | 1            |
| 7  | Will  | 70000  | 1            |
+----+-------+--------+--------------+
Department table:
+----+-------+
| id | name  |
+----+-------+
| 1  | IT    |
| 2  | Sales |
+----+-------+
Output: 
+------------+----------+--------+
| Department | Employee | Salary |
+------------+----------+--------+
| IT         | Max      | 90000  |
| IT         | Joe      | 85000  |
| IT         | Randy    | 85000  |
| IT         | Will     | 70000  |
| Sales      | Henry    | 80000  |
| Sales      | Sam      | 60000  |
+------------+----------+--------+

Constraints:
There are no employees with the exact same name, salary and department.
*/

select department.name as "Department", e.name as "Employee", e.salary as "Salary" from
(select departmentId, name, salary, dense_rank() over(partition by departmentid order by salary desc) as r from Employee) as e
join department on e.departmentId = department.id
where r <= 3;  -- r is the rank of the salary in each department assigned by dense_rank function
