CREATE TABLE players (
    player_id INT PRIMARY KEY,
    player_name VARCHAR(100),
    country VARCHAR(50),
    age INT,
    role VARCHAR(50)
);

INSERT INTO players VALUES
(1, 'Virat Kohli', 'India', 35, 'Batsman'),
(2, 'Babar Azam', 'Pakistan', 30, 'Batsman'),
(3, 'Jasprit Bumrah', 'India', 30, 'Bowler'),
(4, 'Ben Stokes', 'England', 33, 'All-Rounder'),
(5, 'David Warner', 'Australia', 37, 'Batsman');




CREATE TABLE matches (
    match_id INT PRIMARY KEY,
    match_date DATE,
    venue VARCHAR(100),
    team1 VARCHAR(50),
    team2 VARCHAR(50),
    winner VARCHAR(50)
);

INSERT INTO matches VALUES
(101, '2024-10-11', 'Wankhede', 'India', 'Pakistan', 'India'),
(102, '2024-10-15', 'MCG', 'Australia', 'England', 'Australia'),
(103, '2024-10-20', 'Lords', 'India', 'England', 'England'),
(104, '2024-10-25', 'Lahore', 'Pakistan', 'Australia', 'Pakistan');



CREATE TABLE performances (
    perf_id INT PRIMARY KEY,
    player_id INT,
    match_id INT,
    runs INT,
    wickets INT,
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (match_id) REFERENCES matches(match_id)
);

INSERT INTO performances VALUES
(1, 1, 101, 78, 0),
(2, 2, 101, 52, 0),
(3, 3, 101, 5, 3),
(4, 4, 103, 36, 2),
(5, 5, 102, 84, 0),
(6, 1, 103, 45, 0),
(7, 3, 103, 2, 2),
(8, 2, 104, 66, 0);

select*from performances;
select*from players;
select*from matches;

--1. GET THE OLDER PLAYER THAN THE YOUNGEST PLAYER FROM PAKISTSN
-- single row subquery

SELECT*FROM players
where age>
       (select MIN(age) from players);

select * from players
where age>30;

-- 2.get names of players who have played in matches won by india
-- ,multi row subquery

select player_name from players
where country = 'india' AND player_id in (
        select player_id from performances 
        where match_id in (
           select match_id from matches
           where winner = 'india'
           )
);

-- 3.get player  and match combination where the player scored 50+( for workbench)

select player_id,match_id from performances
where (player_id,match_id) in (
      select player_id,match_id
      from performances
      where runs > 50
);

--or run

SELECT p.player_id, p.match_id
FROM performances p
where exists (
    select 1
    from performances sub 
    where sub.player_id = p.player_id
      and sub.match_id = p.match_id
      and sub.runs>50
);



--4. get players who have scored more than 50 in any matches
-- correlated sub query

select p.player_name
from players p
where exists(
        select 1 from performances pf
        where p.player_id = pf.player_id and  pf.runs > 50
    );

-- 5.get average runs per player
-- from clause - subquery

select player_name, ROUND(avg(runs),2) as avg_runs
from(
     select p.player_name, pf.runs
     from performances pf
     join players p
     on p.player_id = pf.player_id
)as stats
group by player_name;

--6.get each player total matches played
-- select sub query

select player_name,
     (select count(*)
     from performances pf
     where p.player_id=pf.player_id) as total_matches
from players p;

-- 7.get player older than all english player for workbench


#all ,any

select * from players
where age > all(
  select player_name
  from players 
  where country = 'England'
  );

  or

SELECT * 
FROM players
WHERE age > ALL (
    SELECT player_id
    FROM players 
    WHERE country = 'England'
);

--8. players who never played in a match  won by england

select player_name from players
where player_id not in (
   select player_id from performances
   where match_id in(
     select match_id from matches
     where winner = 'England'
     )
    );

-- /*scenerio based qs:*/
--9.top scores (runs >=500 in any match

with topscores as(
select player_id,match_id,runs
from performances
where runs >= 70

)
select p.player_name,ts.runs
from topscores ts
join players p
on ts.player_id = p.player_id;

--10.matches won by a players country

SELECT 
    p.country, 
    COUNT(DISTINCT m.match_id) AS matches_won
FROM players p
JOIN performances perf ON p.player_id = perf.player_id
JOIN matches m ON perf.match_id = m.match_id
WHERE m.winner = p.country
GROUP BY p.country;

-- or

with wins as(
  select winner as country , count (*) as wins
  from matches
  group by winner

)
select w.*
from wins w
join players p
on w.country = p.country;

--11. player with highest total runs

SELECT TOP 1 
    p.player_name, 
    p.country, 
    SUM(perf.runs) AS total_runs
FROM players p
JOIN performances perf ON p.player_id = perf.player_id
GROUP BY p.player_name, p.country
ORDER BY total_runs DESC;

--or

WITH PlayerTotalRuns AS (
    SELECT 
        p.player_id,
        p.player_name,
        p.country,
        SUM(perf.runs) AS total_runs
    FROM players p
    JOIN performances perf ON p.player_id = perf.player_id
    GROUP BY p.player_id, p.player_name, p.country
)

SELECT TOP 1 
    player_name, 
    country, 
    total_runs
FROM PlayerTotalRuns
ORDER BY total_runs DESC;

--or

select top 1 p.player_name, sum(pf.runs) as total_runs
from performances pf
join players p
on p. player_id = pf. player_id
group by p.player_name
order by total_runs desc;

--players who played only in india - won matches

WITH player_match_info AS (
    SELECT 
        p.player_id,
        p.player_name,
        m.match_id,
        m.winner
    FROM players p
    JOIN performances pf ON p.player_id = pf.player_id
    JOIN matches m ON pf.match_id = m.match_id
),
non_india_wins AS (
    SELECT DISTINCT player_id
    FROM player_match_info
    WHERE winner != 'India'
)
SELECT DISTINCT player_name
FROM player_match_info
WHERE player_id NOT IN (SELECT player_id FROM non_india_wins);

--or

SELECT DISTINCT p.player_name
FROM performances pf
JOIN players p 
ON pf.player_id = p.player_id
JOIN matches m 
ON pf.match_id = m.match_id
WHERE m.venue = 'Wankhede' AND m.winner ='India';

--12. average wickets by bowlers only 

with bowlerstats as (
     select p.player_name,round(avg(pf.wickets),2)as wickets
     from performances pf
     join players p
     on pf.player_id = p.player_id
     where p.role = 'bowler'
     group by p.player_name
)
select*from bowlerstats;

-- 13.players who never took a wicket

SELECT p.player_id, p.player_name, p.country
FROM players p
LEFT JOIN performances perf ON p.player_id = perf.player_id
GROUP BY p.player_id, p.player_name, p.country
HAVING SUM(ISNULL(perf.wickets, 0)) = 0;

-- (or ) Players who never took a wicket

 
SELECT DISTINCT p.player_name, pf.wickets
FROM performances pf
JOIN players p
ON pf.player_id = p.player_id
WHERE wickets = 0;

--14. Players who played in matches at 'lord'

SELECT DISTINCT p.player_name
FROM performances pf 
    JOIN players p 
    ON pf.player_id = p.player_id
	JOIN matches m 
    ON pf.match_id = m.match_id
WHERE m.venue = 'Lord';

-- 15.all - rounders who scored runs and took wickets

SELECT DISTINCT player_id
FROM performances
WHERE runs > 0 AND wickets > 0;

-- 16.match count per day

SELECT 
    match_date,
    COUNT(*) AS match_count
FROM 
    matches
GROUP BY 
    match_date
ORDER BY 
    match_date;

--17. matches where player took more than 2 wickets

SELECT 
    match_id, 
    player_id, 
    wickets
FROM 
    performances pf
WHERE 
    wickets > 2;

