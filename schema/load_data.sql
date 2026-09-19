-- ==========================================================
-- CSV Data Import Script (PostgreSQL version)
-- Run with:  psql -d covid_db -f load_data_postgres.sql
-- \copy reads files from the CLIENT machine (no server permissions
-- needed) — adjust the paths below to wherever your data/ folder is.
-- ==========================================================

-- 1. Countries
\copy country (country_id, name, continent, population) FROM 'data/countries.csv' WITH (FORMAT csv, HEADER true);

-- 2. States  (note CSV column order: state_id, state_name, population, country_id)
\copy state (state_id, name, population, country_id) FROM 'data/states.csv' WITH (FORMAT csv, HEADER true);

-- 3. Districts
\copy district (district_id, state_id, name) FROM 'data/districts.csv' WITH (FORMAT csv, HEADER true);

-- 4. State-level Covid Cases (district_id stays NULL for these rows)
\copy covid_case_stats (case_id, country_id, state_id, report_date, report_time, confirmed, deaths, recovered, new_confirmed, new_deaths, active_cases) FROM 'data/covid_case_stats.csv' WITH (FORMAT csv, HEADER true);

-- 5. Vaccination
\copy vaccination (vaccine_id, state_id, date, total_doses, first_dose, second_dose, covaxin, covishield, sputnik_v, precaution_dose) FROM 'data/vaccination.csv' WITH (FORMAT csv, HEADER true);

-- 6. Testing (blank fields become NULL automatically with NULL '')
\copy testing (testing_id, state_id, date, total_samples, positive_cases, negative_cases) FROM 'data/testing.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- 7. Global Covid Stats
\copy global_covid_stats (global_stat_id, country_id, report_date, confirmed, deaths, recovered, new_confirmed, new_deaths, active_cases, people_vaccinated_1dose, people_fully_vaccinated) FROM 'data/global_covid_stats.csv' WITH (FORMAT csv, HEADER true);

-- 8. Mumbai district-level Covid Cases
-- IMPORTANT: mumbai_case_stats.csv reuses case_id values 1..521, which
-- collide with the case_id values already used by covid_case_stats.csv.
-- Load it into a staging table first, then insert with an offset ID
-- so both datasets can coexist in the same fact table.
DROP TABLE IF EXISTS mumbai_case_stats_staging;
CREATE TABLE mumbai_case_stats_staging (
  case_id INT,
  country_id INT,
  state_id INT,
  district_id INT,
  report_date DATE,
  report_time TIME,
  confirmed INT,
  deaths INT,
  recovered INT,
  new_confirmed INT,
  new_deaths INT,
  active_cases INT
);

\copy mumbai_case_stats_staging FROM 'data/mumbai_case_stats.csv' WITH (FORMAT csv, HEADER true);

INSERT INTO covid_case_stats
  (case_id, country_id, state_id, district_id, report_date, report_time,
   confirmed, deaths, recovered, new_confirmed, new_deaths, active_cases)
SELECT
  case_id + 100000,  -- offset to avoid clashing with covid_case_stats.csv IDs
  country_id, state_id, district_id, report_date, report_time,
  confirmed, deaths, recovered, new_confirmed, new_deaths, active_cases
FROM mumbai_case_stats_staging;

DROP TABLE mumbai_case_stats_staging;

-- Quick sanity check
SELECT 'country' AS table_name, COUNT(*) FROM country
UNION ALL SELECT 'state', COUNT(*) FROM state
UNION ALL SELECT 'district', COUNT(*) FROM district
UNION ALL SELECT 'covid_case_stats', COUNT(*) FROM covid_case_stats
UNION ALL SELECT 'vaccination', COUNT(*) FROM vaccination
UNION ALL SELECT 'testing', COUNT(*) FROM testing
UNION ALL SELECT 'global_covid_stats', COUNT(*) FROM global_covid_stats;
