SELECT c.name,g.confirmed 
FROM country c JOIN global_covid_stats g
On c.country_id = g.global_stat_id
where g.report_date = '2020-06-30'
Order BY g.confirmed DESC
LIMIT 1;

SELECT
    c.name,
    s.name,
    cs.deaths
FROM covid_case_stats cs
JOIN country c
    ON cs.country_id = c.country_id
JOIN state s
    ON cs.state_id = s.state_id
WHERE cs.report_date = '2020-09-30'
ORDER BY cs.deaths DESC;

SELECT
    c.continent,
    SUM(g.confirmed) AS total_confirmed,
    SUM(g.deaths) AS total_deaths,
    SUM(g.recovered) AS total_recovered
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY c.continent
ORDER BY total_confirmed DESC;

--Aggregate Functions
SELECT
    AVG(g.new_deaths) AS average_new_deaths_per_day
FROM global_covid_stats g;

SELECT
    c.name,
    g.active_cases
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
WHERE g.report_date = '2020-09-30'
ORDER BY g.active_cases DESC
LIMIT 1;

--Stored Procedures
CREATE OR REPLACE PROCEDURE get_recovered_cases(
    IN p_country_id INT,
    IN p_date DATE,
    INOUT p_recovered BIGINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT recovered
    INTO p_recovered
    FROM global_covid_stats
    WHERE country_id = p_country_id
      AND report_date = p_date;
END;
$$;

CREATE OR REPLACE PROCEDURE update_deaths(
    IN p_country_id INT,
    IN p_date DATE,
    IN p_deaths BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE global_covid_stats
    SET deaths = p_deaths
    WHERE country_id = p_country_id
      AND report_date = p_date;
END;
$$;
-- T-SQL
SELECT
    c.name,
    g.confirmed,
    g.deaths,
    g.recovered,
    (g.confirmed + g.deaths + g.recovered) AS total_cases
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id;

SELECT
    c.name,
    g.new_confirmed
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
WHERE g.report_date = '2020-09-30'
  AND g.new_confirmed = (
      SELECT MAX(new_confirmed)
      FROM global_covid_stats
      WHERE report_date = '2020-09-30'
  );