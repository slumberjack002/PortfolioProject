SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portp..coviddeaths
ORDER BY 1, 2

--Total Cases VS Total Deaths

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS DeathPercentage
FROM portp..coviddeaths
WHERE location LIKE '%kingdom%'
ORDER BY 1, 2

--Total Cases VS Population

SELECT location, date, total_cases, population, (CAST(total_cases AS float)/CAST(population AS float))*100 AS InfectionPercentage
FROM portp..coviddeaths
WHERE location LIKE '%kingdom%'
ORDER BY 1, 2

--Highest Infections Rates compared to population

SELECT location, MAX(total_cases) AS HighestInfectionCount, population, MAX((CAST(total_cases AS float)/CAST(population AS float)))*100 AS InfectionPercentage
FROM portp..coviddeaths
GROUP BY location, population
ORDER BY InfectionPercentage DESC

--Highest Death count per population

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM portp..coviddeaths
WHERE continent IS NOT null
GROUP BY location
ORDER BY TotalDeathCount DESC

--Repeat for continent death count

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM portp..coviddeaths
WHERE continent IS NOT null
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global Numbers

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, (SUM(new_deaths)/NULLIF(SUM(new_cases),0))*100 AS DeathPercentage
FROM portp..coviddeaths
WHERE continent IS NOT null
GROUP BY date
ORDER BY 1, 2

--Total population VS Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location , dea.date) AS RollingCount
FROM portp..coviddeaths dea
JOIN portp..covidvaccinations vac
	ON (dea.location=vac.location) AND (dea.date=vac.date)
WHERE dea.continent IS NOT null
ORDER BY 2,3

--Use CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingCount)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location , dea.date) AS RollingCount
FROM portp..coviddeaths dea
JOIN portp..covidvaccinations vac
	ON (dea.location=vac.location) AND (dea.date=vac.date)
WHERE dea.continent IS NOT null
)
SELECT *, (RollingCount/population)*100
FROM PopvsVac
ORDER BY 2, 3

--Temp Table (Acheives same result as CTE)

DROP TABLE IF EXISTS #PercentPeopleVaccinated
CREATE TABLE #PercentPeopleVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingCount numeric
)

INSERT INTO #PercentPeopleVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location , dea.date) AS RollingCount
FROM portp..coviddeaths dea
JOIN portp..covidvaccinations vac
	ON (dea.location=vac.location) AND (dea.date=vac.date)
WHERE dea.continent IS NOT null
ORDER BY 2,3

SELECT *, (RollingCount/population)*100
FROM #PercentPeopleVaccinated


--Creating views to store data for visualisations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location , dea.date) AS RollingCount
FROM portp..coviddeaths dea
JOIN portp..covidvaccinations vac
	ON (dea.location=vac.location) AND (dea.date=vac.date)
WHERE dea.continent IS NOT null

SELECT *
FROM PercentPopulationVaccinated
