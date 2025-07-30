SELECT 
	-- Select the stage and average goals for each stage
	m.stage,
    ROUND(avg(m.home_goal + m.away_goal),2) AS avg_goals,
    -- Select the average overall goals for the 2012/2013 season
    ROUND((SELECT avg(home_goal + away_goal) 
           FROM match 
           WHERE season = '2012/2013'),2) AS overall
FROM match AS m
-- Filter for the 2012/2013 season
WHERE season = '2012/2013'
-- Group by stage
GROUP BY stage;

-- Average goals from league

SELECT 
	l.name AS league,
    -- Select and round the league's total goals
    ROUND(avg(home_goal + m.away_goal), 2) AS avg_goals,
    -- Select & round the average total goals for the season
    (SELECT round(avg(home_goal + away_goal), 2) 
     FROM match
     where season = '2013/2014') AS overall_avg
FROM league AS l
LEFT JOIN match AS m
ON l.country_id = m.country_id
-- Filter for the 2013/2014 season
WHERE season = '2013/2014'
GROUP BY league;


SELECT 
	-- Select the stage and average goals from the subquery
	s.stage,
	ROUND(s.avg_goals,2) AS avg_goals
FROM 
	-- Select the stage and average goals in 2012/2013
	(SELECT
		 stage,
         avg(home_goal + away_goal) AS avg_goals
	 FROM match
	 WHERE season = '2012/2013'
	 GROUP BY stage) AS s
WHERE 
	-- Filter the main query using the subquery
	s.avg_goals > (SELECT avg(home_goal + away_goal) 
                    FROM match WHERE season = '2012/2013'
					GROUP BY s.stage);

SELECT 
	-- Select the stage and average goals from s
	s.stage,
    ROUND(s.avg_goal,2) AS avg_goal,
    -- Select the overall average for 2012/2013
    (select avg(home_goal + away_goal) as avg_goal WHERE season = '2012/2013') AS overall_avg
FROM 
	-- Select the stage and average goals in 2012/2013 from match
	(SELECT
		 stage,
         avg(home_goal + away_goal) AS avg_goals
	 FROM match
	 WHERE season = '2012/2013'
	 GROUP BY stage) AS s
WHERE 
	-- Filter the main query using the subquery
	s.avg_goals > (SELECT avg(home_goal + away_goal) 
                    FROM match WHERE season = '2012/2013');

SELECT 
	-- Select the stage and average goals from s
	s.stage,
    ROUND(s.avg_goals,2) AS avg_goal,
    -- Select the overall average for 2012/2013
    (select avg(home_goal + away_goal) as avg_goal from Match WHERE season = '2012/2013') AS overall_avg
FROM 
	-- Select the stage and average goals in 2012/2013 from match
	(SELECT
		 stage,
         avg(home_goal + away_goal) AS avg_goals
	 FROM match
	 WHERE season = '2012/2013'
	 GROUP BY stage) AS s
WHERE 
	-- Filter the main query using the subquery
	s.avg_goals > (SELECT avg(home_goal + away_goal) 
                    FROM match WHERE season = '2012/2013');

SELECT 
    l.name AS league,
    ROUND(AVG(m.home_goal + m.away_goal),2) AS avg_goals,
    (SELECT ROUND(AVG(home_goal + away_goal),2) 
     FROM match
     WHERE season = '2013/2014') AS overall_avg
FROM league AS l
LEFT JOIN match AS m
ON l.country_id = m.country_id
WHERE m.season = '2013/2014'
GROUP BY l.name;

SELECT 
	-- Select the stage and average goals for each stage
	m.stage,
    ROUND(avg(m.home_goal + m.away_goal),2) AS avg_goals,
    -- Select the average overall goals for the 2012/2013 season
    ROUND((SELECT avg(home_goal + away_goal) 
           FROM match 
           WHERE season = '2012/2013'),2) AS overall
FROM match AS m
-- Filter for the 2012/2013 season
WHERE season = '2012/2013'
-- Group by stage
GROUP BY stage;

SELECT 
	-- Select the stage and average goals from the subquery
	s.stage,
	ROUND(s.avg_goals,2) AS avg_goals
FROM 
	-- Select the stage and average goals in 2012/2013
	(SELECT
		 stage,
         avg(home_goal + away_goal) AS avg_goals
	 FROM match
	 WHERE season = '2012/2013'
	 GROUP BY stage) AS s
WHERE 
	-- Filter the main query using the subquery
	s.avg_goals > (SELECT avg(home_goal + away_goal) 
                    FROM match WHERE season = '2012/2013'
					GROUP BY s.stage);

SELECT 
	-- Select the stage and average goals from s
	s.stage,
    ROUND(s.avg_goal,2) AS avg_goal,
    -- Select the overall average for 2012/2013
    (select avg(home_goal + away_goal) as avg_goal WHERE season = '2012/2013') AS overall_avg
FROM 
	-- Select the stage and average goals in 2012/2013 from match
	(SELECT
		 stage,
         avg(home_goal + away_goal) AS avg_goals
	 FROM match
	 WHERE season = '2012/2013'
	 GROUP BY stage) AS s
WHERE 
	-- Filter the main query using the subquery
	s.avg_goals > (SELECT avg(home_goal + away_goal) 
                    FROM match WHERE season = '2012/2013');

SELECT 
	-- Select the stage and average goals from s
	s.stage,
    ROUND(s.avg_goals,2) AS avg_goal,
    -- Select the overall average for 2012/2013
    (select avg(home_goal + away_goal) as avg_goal from Match WHERE season = '2012/2013') AS overall_avg
FROM 
	-- Select the stage and average goals in 2012/2013 from match
	(SELECT
		 stage,
         avg(home_goal + away_goal) AS avg_goals
	 FROM match
	 WHERE season = '2012/2013'
	 GROUP BY stage) AS s
WHERE 
	-- Filter the main query using the subquery
	s.avg_goals > (SELECT avg(home_goal + away_goal) 
                    FROM match WHERE season = '2012/2013');