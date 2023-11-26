


SELECT * FROM plogdb.`covid death`
WHERE continent is not null
ORDER BY 3 ASC, 4 DESC;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM plogdb.`covid death`
ORDER BY 1 ASC, 2;

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_rate
FROM plogdb.`covid death`
WHERE location LIKE 'Nigeria'
ORDER BY 1 ASC, 2;

''look at total cases vs population 

SELECT location, date,  population, total_cases, (total_cases/population)*100 AS death_rate
FROM plogdb.`covid death`
WHERE location LIKE 'Nigeria'
ORDER BY 1 ASC, 2;

''what coundtry has the highst rate of covid


SELECT location, MAX(population) AS HighestPopulation, MAX(total_cases) AS HighestPopulationCount, MAX((total_cases/population)*100) AS PercentageOfPopulationInfected
FROM plogdb.`covid death`
GROUP BY location
ORDER BY PercentageOfPopulationInfected DESC;


''HIghest deathcount er country(popuation)


SELECT location, MAX(total_deaths) AS totaldeathcount
FROM plogdb.`covid death`
WHERE continent is not null
GROUP BY location
ORDER BY totaldeathcount DESC;



'' shwoing the continent with the hightest death count 


SELECT continent, MAX(total_deaths) AS totaldeathcount
FROM plogdb.`covid death`
WHERE continent is not null
GROUP BY continent
ORDER BY totaldeathcount DESC;

''GLOBAL NUMBERS

SELECT  date, MAX(total_cases) AS max_total_cases, MAX(total_deaths) AS max_total_deaths, MAX((total_deaths/total_cases)*100) AS max_death_rate
FROM plogdb.`covid death`
GROUP BY date
ORDER BY date ASC;

SELECT location, date, MAX(total_cases) AS max_total_cases, MAX(total_deaths) AS max_total_deaths, MAX((total_deaths/total_cases)*100) AS max_death_rate
FROM plogdb.`covid death`
WHERE location =  'Nigeria'
GROUP BY date
ORDER BY date ASC;


SELECT date,SUM(total_cases) AS sum_total_cases,SUM(total_deaths) AS sum_total_deaths,(SUM(total_deaths ) / SUM(total_cases)) * 100 AS DeathPercentage
FROM plogdb.`covid death`
GROUP BY date
ORDER BY date ASC;




SELECT SUM(total_cases) AS sum_total_cases,SUM(total_deaths) AS sum_total_deaths,(SUM(total_deaths ) / SUM(total_cases)) * 100 AS DeathPercentage
FROM plogdb.`covid death`
ORDER BY date ASC;



''LOOKING AT TOTAL POPULATION VS VACCIATION

SELECT *
FROM plogdb.`covid vacinations` AS vac
JOIN plogdb.`covid death` AS dea
ON dea.location = vac.location
AND dea.date = vac.date;


SELECT  dea.continent , dea.location, dea.date, dea.population , vac.new_vaccinations
FROM plogdb.`covid vacinations` AS vac
JOIN plogdb.`covid death` AS dea
ON dea.location = vac.location
AND dea.date = vac.date
ORDER BY date ASC;


SELECT  dea.continent , dea.location, dea.date, dea.population , vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location) AS vaccinatedPopulation
FROM plogdb.`covid vacinations` AS vac
JOIN plogdb.`covid death` AS dea
ON dea.location = vac.location
AND dea.date = vac.date
ORDER BY date ASC;



-- Using CTE to perform Calculation on Partition By in previous query 

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, People_Vaccinated)
AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as People_Vaccinated
    FROM
        plogdb.`covid death` AS dea
    JOIN
        plogdb.`Covid Vacinations` AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
    ORDER BY
        dea.location, dea.date
)
SELECT
    Continent,
    Location,
    Date,
    Population,
    New_Vaccinations,
    People_Vaccinated,
    (People_Vaccinated / Population) * 100 as VaccinationPercentage
FROM
    PopvsVac;



-- Using Temp Table to perform Calculation on Partition By in previous query



USE plogdb;
-- Drop the table if it exists
DROP TABLE IF EXISTS PercentPopulationVaccinated;

-- Create the table
CREATE TABLE PercentPopulationVaccinated
(
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATE,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Insert data into the table
INSERT INTO PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    STR_TO_DATE(dea.date, '%d/%m/%Y'),
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM
    plogdb.`covid death` AS dea
JOIN
    plogdb.`covid vacinations` AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

-- Select data from the table
SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM
    PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date,  dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated,
    (SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) / dea.population) * 100 AS VaccinationPercentage
FROM
    plogdb.`covid death` as dea
JOIN
    plogdb.`covid vacinations` as vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;

