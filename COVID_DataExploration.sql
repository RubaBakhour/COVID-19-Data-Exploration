

-- Covid 19 Data Exploration 
SELECT *
FROM DatabaseProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3
	,4

-- Total Cases vs Total Deaths
-- The liklihood of you contract covid in Saudi Arabia
SELECT location
	,DATE
	,total_cases
	,total_deaths
	,(total_deaths / total_cases) * 100 AS DeathPercentage
FROM DatabaseProject..CovidDeaths
WHERE location LIKE '%Arabia%'
	AND continent IS NOT NULL
ORDER BY 1
	,2

-- Total Cases vs Population
-- Percentage of population got covid
SELECT location
	,DATE
	,total_cases
	,population
	,(total_cases / population) * 100 AS PercentofPopulationInfected
FROM DatabaseProject..CovidDeaths
ORDER BY 1
	,2

-- Countries with highest Infection rate compared to population
SELECT Location
	,Population
	,MAX(total_cases) AS HighestInfectionCount
	,MAX((total_cases / population) * 100) AS PercentofPopulationInfected
FROM DatabaseProject..CovidDeaths
GROUP BY Location
	,population
ORDER BY PercentofPopulationInfected DESC

-- Countries with Highest Death Count per Population
SELECT Location
	,MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM DatabaseProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Contintents with Highest Death Count per Population
SELECT continent
	,MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM DatabaseProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
SELECT DATE
	,SUM(new_cases) AS TotalNewCases
	,SUM(cast(new_deaths AS INT)) AS TotalDeathCount
	,SUM(cast(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM DatabaseProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY DATE
ORDER BY 1
	,2

-- Total Population vs Vaccination
-- Percentage of Population that has recieved at least one Covid Vaccine
SELECT death.continent
	,death.location
	,death.DATE
	,death.population
	,vac.new_vaccinations
	,SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
		PARTITION BY death.Location ORDER BY death.location
			,death.DATE
		) AS RollingPeopleVaccinated
FROM DatabaseProject..CovidDeaths death
JOIN DatabaseProject..CovidVaccinations vac ON death.location = vac.location
	AND death.DATE = vac.DATE
WHERE death.continent IS NOT NULL
ORDER BY 1
	,2
	,3
-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac(Continent, Location, DATE, Population, New_Vaccinations, RollingPeopleVaccinated) AS (
		SELECT death.continent
			,death.location
			,death.DATE
			,death.population
			,vac.new_vaccinations
			,SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
				PARTITION BY death.Location ORDER BY death.location
					,death.DATE
				) AS RollingPeopleVaccinated
		--, (RollingPeopleVaccinated/population)*100
		FROM DatabaseProject..CovidDeaths death
		JOIN DatabaseProject..CovidVaccinations vac ON death.location = vac.location
			AND death.DATE = vac.DATE
		WHERE death.continent IS NOT NULL
		)

--order by 2,3
SELECT *
	,(RollingPeopleVaccinated / Population) * 100 AS PercentVaccinated
FROM PopvsVac 

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE

IF EXISTS #PercentPopulationVaccinated
	CREATE TABLE #PercentPopulationVaccinated (
		Continent NVARCHAR(255)
		,Location NVARCHAR(255)
		,DATE DATETIME
		,Population NUMERIC
		,New_vaccinations NUMERIC
		,RollingPeopleVaccinated NUMERIC
		)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent
	,death.location
	,death.DATE
	,death.population
	,vac.new_vaccinations
	,SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
		PARTITION BY death.Location ORDER BY death.location
			,death.DATE
		) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM DatabaseProject..CovidDeaths death
JOIN DatabaseProject..CovidVaccinations vac ON death.location = vac.location
	AND death.DATE = vac.DATE

--where death.continent is not null 
--order by 2,3
SELECT *
	,(RollingPeopleVaccinated / Population) * 100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated
AS
SELECT death.continent
	,death.location
	,death.DATE
	,death.population
	,vac.new_vaccinations
	,SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
		PARTITION BY death.Location ORDER BY death.location
			,death.DATE
		) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM DatabaseProject..CovidDeaths death
JOIN DatabaseProject..CovidVaccinations vac ON death.location = vac.location
	AND death.DATE = vac.DATE
WHERE death.continent IS NOT NULL

