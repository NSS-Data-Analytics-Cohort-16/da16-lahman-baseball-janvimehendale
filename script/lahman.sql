-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 
--range of years - appearances


SELECT
	*	
FROM appearances
LIMIT 5;

SELECT
	DISTINCT yearid
FROM appearances
GROUP BY yearid;

SELECT
	MIN(yearid) AS min,--1871
	MAX(yearid) AS max --2016
FROM appearances
LIMIT 1;
--1871 to 2016
--------------------------------------------------------------------------------------------------------
-- 2. Find the name and height of the shortest player in the database. How many games did he play in? 
--What is the name of the team for which he played?
   
--name and height - people
-- no of games - appearances
--team name - teams

SELECT
	* 
FROM people
WHERE namefirst ILIKE '%Eddie%'
AND namelast ILIKE '%Gaedel%'
LIMIT 5;

--Find shortest player - "Eddie"	"Gaedel"	43 "gaedeed01"
SELECT 
	--p.playerid,
	CONCAT(p.namefirst, ' ', p.namelast) AS full_name,
	MIN(p.height) AS height,
	a.g_all AS games_played,
	t.name AS team_name -- "St. Louis Browns"
--	(SELECT teamid FROM appearances)- getting error 
			-- more than one row returned by a subquery used as an expression
FROM people p
INNER JOIN appearances a -- teamid SLA
USING (playerid)
INNER JOIN teams t
USING (teamid)
WHERE playerid = 'gaedeed01'
GROUP BY full_name, playerid, a.teamid, t.name, a.g_all
ORDER by height
--"Eddie"	"Gaedel"	"Edward Carl"	43	"SLA"	1	"St. Louis Browns"

--------------------------------------------------------------------------------------------------------
-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each
--player’s first and last names as well as the total salary they earned in the major leagues. 
--Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the
--most money in the majors?
--all players first name, last name - people
-- total salary - salaries
-- Vanderbilt -school name - schools
			-- schoolid - collegeplaying
-- league name - homegames 
---NEED HELP

SELECT
	DISTINCT league,
	games
FROM homegames;

SELECT
	c.playerid, c.schoolid, s.salary, s.lgid
FROM collegeplaying c
INNER JOIn salaries s USING (playerid)
WHERE schoolid = 'vandy'

SELECT * FROM salaries


SELECT
	CONCAT(p.namefirst, ' ', p.namelast) AS full_name,
	SUM(sal.salary::NUMERIC::MONEY) AS total_salary,
	a.lgid
	--(SELECT 
		--SUM(sal.salary::NUMERIC::MONEY) AS total_salary,
	 	--sal.lgid 
		 --FROM salaries sal
		--GROUP BY sal.lgid)
FROM people p
INNER JOIN collegeplaying c USING (playerid)
INNER JOIN schools s ON s.schoolid = c.schoolid
INNER JOIN salaries sal USING (playerid)
INNER JOIN appearances a USING (playerid)
--INNER JOIN homegames h ON h.league = a.lgid 
--INNER JOIN teams t ON t.lgid = a.lgid 
--INNER JOIN managers m ON m.lgid = a.lgid 
WHERE s.schoolname ILIKE '%VANDERBILT%'
--AND UPPER(a.lgid) IN ('AA', 'UA', 'PL', 'FL')
GROUP BY full_name, a.lgid	 
ORDER BY total_salary DESC;

SELECT playerid, lgid FROM appearances
INNER JOIN people p USING (playerid)

WHERE lgid IN ('AA', 'UA', 'PL', 'FL')

--------------------------------------------------------------------------------------------------------
-- 4. Using the fielding table, group players into three groups based on their position: label players
--with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and 
--those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these 
--three groups in 2016.
--fielding position

SELECT 
CASE WHEN pos = 'OF' THEN 'Outfield'
	 WHEN pos IN ('P', 'C') THEN 'Battery'
	 ELSE 'Infield' END AS position,
	 SUM(po) AS total_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position

--------------------------------------------------------------------------------------------------------
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report
--to 2 decimal places. Do the same for home runs per game. Do you see any trends?
   
--avg(strikeouts) decade 1920 onwards, 
--avg(homeruns)

SELECT
	yearid/10*10 AS decade,
	ROUND(SUM(SO)::NUMERIC/SUM(g)::NUMERIC,2) AS avg_strikeouts,
	ROUND(SUM(HR)::NUMERIC/SUM(g)::NUMERIC,2) AS avg_homeruns
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade--pattern - avg strikeouts increased every decade except 1970 where it dropped a
--little than last year but increased the following year.

--------------------------------------------------------------------------------------------------------
-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as
--the percentage of stolen base attempts which are successful. (A stolen base attempt results either in 
--a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen
--bases.
--playerid/ name - 2016  
--stealing bases >20
--percentage

SELECT
	--(SELECT CONCAT(p.namefirst, ' ', p.namelast)AS full_name
	--	FROM people p),-------------------GETTING ERROR
	CONCAT(p.namefirst, ' ', p.namelast)AS full_name,
	SUM(b.SB) AS sb_count,
	(b.SB+b.CS) AS attempts,
	ROUND(SUM(b.SB)::NUMERIC*100/SUM(b.SB+b.CS)::NUMERIC,2) AS percentage
FROM batting b
INNER JOIN people p USING (playerid)
WHERE b.yearid = 2016
AND (b.SB+b.CS)>=20 
GROUP BY b.playerid, p.namefirst, p.namelast, b.sb, b.cs
ORDER BY percentage DESC

--------------------------------------------------------------------------------------------------------
-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world 
--series? What is the smallest number of wins for a team that did win the world series? Doing this
--will probably result in an unusually small number of wins for a world series champion – determine 
--why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016
--was it the case that a team with the most wins also won the world series? What percentage of the time?

--yearid 1970 -2016
--count(max(win))
--count(min(win))

SELECT
	teamid,
	COUNT(divwin) AS division_winner,
	COUNT(wcwin) AS wildcard_winner,
	COUNT(lgwin) AS league_winner,
	COUNT(wswin) AS worldseries_winner
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY teamid, yearid;

--largest number of wins for a team that did not win the world series
WITH lost_ws AS(
	SELECT teamid,
	yearid,
	COUNT(*)FILTER (
				WHERE divwin = 'Y'
				OR wcwin = 'Y'
				OR lgwin = 'Y') AS win
FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
GROUP BY teamid, yearid
--ORDER BY win DESC
), --ATL 17

--smallest number of wins for a team that did win the world series
won_ws AS(
	SELECT teamid,
	yearid,
	COUNT(*)FILTER (
				WHERE divwin = 'Y'
				OR wcwin = 'Y'
				OR lgwin = 'Y') AS win
FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y'
GROUP BY teamid, yearid
--ORDER BY win --ARI	1 (total 7 with 1 win)
)

-- most wins including the world series
--won_all AS(
--	SELECT teamid,
	--COUNT(*)FILTER (
		--		WHERE divwin = 'Y'
			--	OR wcwin = 'Y'
			--	OR lgwin = 'Y') AS win
--FROM teams
--	WHERE yearid BETWEEN 1970 AND 2016
--	AND wswin = 'Y'
--GROUP BY lost_ws.teamid, won_ws.teamid
--),

SELECT 
	*,
	max(win) AS win
FROM lost_ws 
GROUP BY lost_ws.teamid, lost_ws.yearid

UNION
SELECT
	*,
	min(win) 
FROM won_ws 
GROUP BY won_ws.teamid, won_ws.yearid

--UNION ALL
--SELECT * FROM won_all ORDER BY win DESC LIMIT 1
--------------------------------------------------------------------------------------------------------
-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the 
--top 5 average attendance per game in 2016 (where average attendance is defined as total attendance
--divided by number of games). Only consider parks where there were at least 10 games played. Report
--the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
--attendance - homegames
--teams
--parks
--games =>10

SELECT 
	--(SELECT park_name FROM parks),
	p.park_name,
	h.attendance,
	h.team,
--	t.name,
	h.games,
	h.attendance/ h.games AS attendance_per_game
FROM homegames h
INNER JOIN parks p ON p.park = h.park
--INNER JOIN teams t ON t.teamid = h.team --getting same record 5 times 
WHERE year = 2016
ORDER BY attendance_per_game DESC
LIMIT 5;


SELECT 
	--(SELECT park_name FROM parks),
	p.park_name,
	h.attendance,
	h.team,
--	t.name,
	h.games,
	h.attendance/ h.games AS attendance_per_game
FROM homegames h
INNER JOIN parks p ON p.park = h.park
--INNER JOIN teams t ON t.teamid = h.team
WHERE year = 2016
ORDER BY attendance_per_game 
LIMIT 5;

--------------------------------------------------------------------------------------------------------
-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and
--the American League (AL)? Give their full name and the teams that they were managing when they won 
--the award.

--manager full name
--team
--NL and AL
SELECT
	CONCAT(p.namefirst,' ', p.namelast) AS full_name,
	a1.lgid,
	a1.yearid
FROM awardsmanagers a1
INNER JOIN people p USING (playerid)
WHERE awardid = 'TSN Manager of the Year'
AND lgid = 'NL'
INTERSECT--DIDN'T WORK
SELECT
	CONCAT(p.namefirst,' ', p.namelast) AS full_name,
	a2.lgid,
	a2.yearid
FROM awardsmanagers a2
INNER JOIN people p USING (playerid)
WHERE awardid = 'TSN Manager of the Year'
AND lgid = 'AL'


SELECT
	CONCAT(p.namefirst,' ', p.namelast) AS full_name,
	a.yearid AS year,
	a.lgid AS league,
	(SELECT
		a1.yearid AS year,
		a1.lgid AS league
		FROM awardsmanagers a1
	WHERE a1.awardid = 'TSN Manager of the Year'
	AND a1.lgid IS NOT NULL
	AND a1.lgid = 'NL') 
FROM awardsmanagers a
INNER JOIN people p USING (playerid)
INNER JOIN awardsmanagers a1 USING (playerid)
WHERE a.awardid = 'TSN Manager of the Year'
AND a.lgid IS NOT NULL
AND a.lgid = 'AL' 



UNION
SELECT
	CONCAT(p.namefirst,' ', p.namelast) AS full_name,
	a1.yearid AS year,
	a1.lgid AS league
FROM awardsmanagers a1
INNER JOIN people p USING (playerid)
WHERE a1.awardid = 'TSN Manager of the Year'
AND a1.lgid IS NOT NULL
AND a1.lgid = 'NL' --GROUP BY a.lgid, full_name, p.namefirst, p.namelast, a.yearid
ORDER BY full_name;

--------------------------------------------------------------------------------------------------------
-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players
--who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
--Report the players' first and last names and the number of home runs they hit in 2016.


--------------------------------------------------------------------------------------------------------
-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to
--answer this question. As you do this analysis, keep in mind that salaries across the whole league 
--tend to increase together, so you may want to look on a year-by-year basis.

--------------------------------------------------------------------------------------------------------
-- 12. In this question, you will explore the connection between number of wins and attendance.
--   *  Does there appear to be any correlation between attendance at home games and number of wins? </li>
--   *  Do teams that win the world series see a boost in attendance the following year? What about teams 
--that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

--------------------------------------------------------------------------------------------------------
-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less 
--often, that they are more effective. Investigate this claim and present evidence to either support or
--dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed
--pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to
--make it into the hall of fame?

--------------------------------------------------------------------------------------------------------

  
