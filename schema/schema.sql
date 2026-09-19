

-- Drop tables if re-running (order matters: children before parents)
DROP TABLE IF EXISTS global_covid_stats;
DROP TABLE IF EXISTS testing;
DROP TABLE IF EXISTS vaccination;
DROP TABLE IF EXISTS covid_case_stats;
DROP TABLE IF EXISTS district;
DROP TABLE IF EXISTS state;
DROP TABLE IF EXISTS country;

-- 1. Country Dimension
CREATE TABLE country (
  country_id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  continent VARCHAR(50) NOT NULL,
  population BIGINT NOT NULL
);

-- 2. State Dimension
CREATE TABLE state (
  state_id INT PRIMARY KEY,
  country_id INT NOT NULL REFERENCES country (country_id),
  name VARCHAR(100) NOT NULL,
  population BIGINT NOT NULL,
  CONSTRAINT uq_state_country_name UNIQUE (country_id, name)
);

-- 3. District Dimension
CREATE TABLE district (
  district_id INT PRIMARY KEY,
  state_id INT NOT NULL REFERENCES state (state_id),
  name VARCHAR(100) NOT NULL,
  CONSTRAINT uq_district_state_name UNIQUE (state_id, name)
);

-- 4. State & District Level Covid Case Fact Table
CREATE TABLE covid_case_stats (
  case_id INT PRIMARY KEY,
  country_id INT NOT NULL REFERENCES country (country_id),
  state_id INT NOT NULL REFERENCES state (state_id),
  district_id INT NULL REFERENCES district (district_id),
  report_date DATE NOT NULL,
  report_time TIME NOT NULL DEFAULT '08:00:00',
  confirmed INT NOT NULL DEFAULT 0,
  deaths INT NOT NULL DEFAULT 0,
  recovered INT NOT NULL DEFAULT 0,
  new_confirmed INT NOT NULL DEFAULT 0,
  new_deaths INT NOT NULL DEFAULT 0,
  active_cases INT NOT NULL DEFAULT 0,
  CONSTRAINT uq_case_scope_date UNIQUE (country_id, state_id, district_id, report_date)
);

-- 5. Vaccination Fact Table (with vaccine brand breakdown)
CREATE TABLE vaccination (
  vaccine_id INT PRIMARY KEY,
  state_id INT NOT NULL REFERENCES state (state_id),
  date DATE NOT NULL,
  total_doses BIGINT NOT NULL DEFAULT 0,
  first_dose BIGINT NOT NULL DEFAULT 0,
  second_dose BIGINT NOT NULL DEFAULT 0,
  covaxin BIGINT NOT NULL DEFAULT 0,
  covishield BIGINT NOT NULL DEFAULT 0,
  sputnik_v BIGINT NOT NULL DEFAULT 0,
  precaution_dose BIGINT NOT NULL DEFAULT 0,
  CONSTRAINT uq_vaccine_state_date UNIQUE (state_id, date)
);

-- 6. Testing Fact Table
CREATE TABLE testing (
  testing_id INT PRIMARY KEY,
  state_id INT NOT NULL REFERENCES state (state_id),
  date DATE NOT NULL,
  total_samples BIGINT NOT NULL DEFAULT 0,
  positive_cases NUMERIC NULL,
  negative_cases NUMERIC NULL,
  CONSTRAINT uq_testing_state_date UNIQUE (state_id, date)
);

-- 7. Global Covid Stats (for international & continental use cases)
CREATE TABLE global_covid_stats (
  global_stat_id INT PRIMARY KEY,
  country_id INT NOT NULL REFERENCES country (country_id),
  report_date DATE NOT NULL,
  confirmed BIGINT NOT NULL DEFAULT 0,
  deaths BIGINT NOT NULL DEFAULT 0,
  recovered BIGINT NOT NULL DEFAULT 0,
  new_confirmed BIGINT NOT NULL DEFAULT 0,
  new_deaths BIGINT NOT NULL DEFAULT 0,
  active_cases BIGINT NOT NULL DEFAULT 0,
  people_vaccinated_1dose BIGINT NOT NULL DEFAULT 0,
  people_fully_vaccinated BIGINT NOT NULL DEFAULT 0,
  CONSTRAINT uq_global_country_date UNIQUE (country_id, report_date)
);

-- Indexes to boost analytical query performance
CREATE INDEX idx_cases_date ON covid_case_stats (report_date);
CREATE INDEX idx_cases_state_date ON covid_case_stats (state_id, report_date);
CREATE INDEX idx_vaccine_date ON vaccination (date);
CREATE INDEX idx_testing_date ON testing (date);
CREATE INDEX idx_global_date ON global_covid_stats (report_date);
