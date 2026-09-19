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

 -- VIEWS

CREATE OR REPLACE VIEW country_covid_summary AS
SELECT
    c.country_id,
    c.name,
    g.report_date,
    g.confirmed,
    g.deaths,
    g.recovered

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

CREATE OR REPLACE VIEW latest_country_covid_data AS
SELECT
    country_id,
    name,
    report_date,
    confirmed,
    deaths,
    recovered
FROM (
    SELECT
        c.country_id,
        c.name,
        g.report_date,
        g.confirmed,
        g.deaths,
        g.recovered,
        ROW_NUMBER() OVER (
            PARTITION BY c.country_id
            ORDER BY g.report_date DESC
        ) AS rn
    FROM global_covid_stats g
    JOIN country c
        ON g.country_id = c.country_id
) x
WHERE rn = 1;
=======
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

--CTE
WITH weekly_data AS (
    SELECT
        country_id,
        report_date,
        confirmed,
        LAG(confirmed, 7) OVER (
            PARTITION BY country_id
            ORDER BY report_date
        ) AS confirmed_7_days_ago
    FROM global_covid_stats
)
SELECT
    c.name,
    report_date,
    confirmed,
    confirmed_7_days_ago,
    ROUND(
        (
            (confirmed - confirmed_7_days_ago) * 100.0
            / NULLIF(confirmed_7_days_ago, 0)
        ),
        2
    ) AS percentage_increase
FROM weekly_data w
JOIN country c
    ON w.country_id = c.country_id
WHERE confirmed_7_days_ago IS NOT NULL;

WITH latest_date AS (
    SELECT MAX(report_date) AS max_date
    FROM global_covid_stats
),
latest_data AS (
    SELECT
        g.country_id,
        g.active_cases
    FROM global_covid_stats g
    JOIN latest_date l
        ON g.report_date = l.max_date
)
SELECT
    c.name,
    ld.active_cases
FROM latest_data ld
JOIN country c
    ON ld.country_id = c.country_id
ORDER BY ld.active_cases DESC
LIMIT 1;

-- UDF
CREATE OR REPLACE FUNCTION mortality_rate(
    p_country_id INT
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_confirmed BIGINT;
    v_deaths BIGINT;
BEGIN

    SELECT
        confirmed,
        deaths
    INTO
        v_confirmed,
        v_deaths
    FROM global_covid_stats
    WHERE country_id = p_country_id
    ORDER BY report_date DESC
    LIMIT 1;

    RETURN ROUND(
        (v_deaths * 100.0) / NULLIF(v_confirmed, 0),
        2
    );

END;
$$;

CREATE OR REPLACE FUNCTION recovery_rate(
    p_country_id INT,
    p_date DATE
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_confirmed BIGINT;
    v_recovered BIGINT;
BEGIN

    SELECT
        confirmed,
        recovered
    INTO
        v_confirmed,
        v_recovered
    FROM global_covid_stats
    WHERE country_id = p_country_id
      AND report_date = p_date;

    RETURN ROUND(
        (v_recovered * 100.0) / NULLIF(v_confirmed, 0),
        2
    );

END;
$$;

--GroupBy
SELECT
    c.continent,
    SUM(g.confirmed) AS total_confirmed
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY c.continent
ORDER BY total_confirmed DESC;

SELECT
    report_date,
    SUM(deaths) AS total_deaths,
    SUM(recovered) AS total_recovered
FROM global_covid_stats
GROUP BY report_date
ORDER BY report_date;

SELECT
    c.name,
    AVG(g.new_confirmed) AS average_daily_new_cases
FROM global_covid_stats g
JOIN country c
    ON g.country_id = c.country_id
GROUP BY c.name
ORDER BY average_daily_new_cases DESC;