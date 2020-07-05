DROP VIEW IF EXISTS q0, q1i, q1ii, q1iii, q1iv, q2i, q2ii, q2iii, q3i, q3ii, q3iii, q4i, q4ii, q4iii, q4iv, q4v;

-- Question 0
CREATE VIEW q0(era) 
AS
  SELECT MAX(era) 
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst ~ '^.* .*$'
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height) as avgheight, COUNT(*) as count 
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height) as avgheight, COUNT(*) as count 
  FROM people
  GROUP BY birthyear
  HAVING AVG(height) > 70
  ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, people.playerid, yearid
  FROM people, HallOfFame
  WHERE people.playerid = HallOfFame.playerid 
  AND inducted = 'Y'
  ORDER BY yearid DESC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT namefirst, namelast, people.playerid, Schools.schoolid, HallOfFame.yearid
  FROM people, HallOfFame, Schools, CollegePlaying
  WHERE people.playerid = HallOfFame.playerid 
  AND people.playerid = CollegePlaying.playerid
  AND CollegePlaying.schoolid = Schools.schoolid
  AND Schools.schoolState = 'CA'
  AND inducted = 'Y'
  ORDER BY yearid DESC, schoolid, playerid ASC
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT p.playerid, namefirst, namelast, schoolid
  FROM people p INNER JOIN HallOfFame h 
  ON p.playerid = h.playerid 
  LEFT OUTER JOIN CollegePlaying c
  ON h.playerid = c.playerid
  WHERE inducted = 'Y'
  ORDER BY playerid DESC, schoolid ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, namefirst, namelast, b.yearid, (b.H + b.H2B + 2 * b.H3B + 3 * b.HR) * 1.0/b.AB as slg
  FROM people p INNER JOIN batting b
  ON p.playerid = b.playerid
  WHERE AB > 50 
  ORDER BY slg DESC, yearid, playerid ASC
  LIMIT 10 
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid, namefirst, namelast, (SUM(b.H) + SUM(b.H2B) + 2 * SUM(b.H3B) + 3 * SUM(b.HR)) * 1.0 / SUM(b.AB) as lslg
  FROM people p INNER JOIN batting b
  ON p.playerid = b.playerid
  GROUP BY p.playerid
  HAVING SUM(b.AB) > 50
  ORDER BY lslg DESC, playerid ASC
  LIMIT 10 
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT namefirst, namelast, (SUM(b.H) + SUM(b.H2B) + 2 * SUM(b.H3B) + 3 * SUM(b.HR)) * 1.0 / SUM(b.AB) as lslg
  FROM people p INNER JOIN batting b
  ON p.playerid = b.playerid
  GROUP BY p.playerid
  HAVING SUM(b.AB) > 50
  AND (SUM(b.H) + SUM(b.H2B) + 2 * SUM(b.H3B) + 3 * SUM(b.HR)) * 1.0 / SUM(b.AB) > 
  (SELECT (SUM(b.H) + SUM(b.H2B) + 2 * SUM(b.H3B) + 3 * SUM(b.HR)) * 1.0 / SUM(b.AB) as lslg
  FROM people p INNER JOIN batting b
  ON p.playerid = b.playerid
  WHERE p.playerid = 'mayswi01'
  GROUP BY p.playerid)
  ORDER BY namefirst ASC, lslg DESC
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg, stddev)
AS
  WITH MEAN AS (
    SELECT yearid, AVG(salary) AS avg
    FROM salaries
    GROUP BY yearid 
  ), DEVIATION AS (
    SELECT salaries.yearid, salary, avg, POWER(salary - MEAN.avg, 2) AS Error
    FROM salaries INNER JOIN MEAN
    ON salaries.yearid = MEAN.yearid
  ) SELECT yearid, MIN(salary) as min, MAX(salary) as max, AVG(DEVIATION.avg) as avg,
  SQRT(SUM(Error) / (COUNT(*) - 1)) as stddev
  FROM DEVIATION
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  WITH params AS (
  -- Parameters for down stream queries
  SELECT
    10 AS bucket_count
),
numbers AS (
  SELECT salary AS num
  FROM params, salaries 
  WHERE yearid = 2016
),
overall AS (
  SELECT MIN(num) min_num,
  MAX(num) max_num
  FROM numbers
), 
buckets AS (
    -- Build list of buckets range
  SELECT bucket,
  floor(min_num + ((max_num - min_num)::numeric / bucket_count) * bucket)::int AS min_range,
  floor(min_num + ((max_num - min_num)::numeric / bucket_count) * (bucket + 1))::int AS max_range
  FROM params,
  overall,
  generate_series(0, bucket_count - 1) AS t(bucket)
)
  SELECT 
  bucket,
  min_range,
  max_range,
  COUNT(num) as count_num
  FROM numbers
  JOIN buckets ON (numbers.num = max_range OR (numbers.num < max_range and numbers.num >= min_range))
  GROUP BY bucket, min_range, max_range
  ORDER BY bucket
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  WITH previous AS (
  SELECT (yearid + 1) as newYearid, MIN(salary) as min, MAX(salary) as max, AVG(salary) as avg
  FROM salaries 
  GROUP BY newYearid
),
current AS (
  SELECT yearid, MIN(salary) as min, MAX(salary) as max, AVG(salary) as avg
  FROM salaries 
  GROUP BY yearid
)
SELECT c.yearid, (c.min - p.min) as mindiff, (c.max - p.max) as maxdiff, (c.avg - p.avg) as avgdiff
FROM previous p INNER JOIN current c
ON p.newYearid = c.yearid
ORDER BY c.yearid
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
SELECT s.playerid, namefirst, namelast, salary, yearid
FROM salaries s INNER JOIN people p
ON  s.playerid = p.playerid
WHERE s.yearid = 2000 and s.salary = 
(SELECT MAX(s2.salary) FROM salaries s2 WHERE s2.yearid = 2000)

UNION

SELECT s.playerid, namefirst, namelast, salary, yearid
FROM salaries s INNER JOIN people p
ON  s.playerid = p.playerid
WHERE s.yearid = 2001 and s.salary = 
(SELECT MAX(s2.salary) FROM salaries s2 WHERE s2.yearid = 2001)
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
SELECT a.teamid, (max(salary) - min(salary)) as diffAvg
FROM AllstarFull a INNER JOIN salaries s
ON a.playerid = s.playerid
AND a.yearid = s.yearid
WHERE a.yearid = 2016
GROUP BY a.teamid
ORDER BY a.teamid
;

