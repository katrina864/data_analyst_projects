-- Queries that output excel tables used in Tableau visualization

-- 1. 

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2

-- 2. 

-- We take these out as they are not included in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

-- 3.

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by location, population
order by PercentPopulationInfected desc

-- 4.

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc

-- Beginning of the rest of my queries

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations$
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in the US

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States' and continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population infected with covid

SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States' and continent is not null
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, MAX(total_cases) as HighestInfectionCount, population, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count compared to Population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Continent correct values

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Showing Continents with Highest Death Count

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global death percentage each day

SELECT date, SUM(new_cases) as new_cases, SUM(cast(new_deaths as int)) as new_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- Global death rate all time

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations (accumulated number) using partition by

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location
	ORDER BY dea.location, dea.date) as PeopleVaccinatedAccumulated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Using CTE to find percent of population vaccinated (accumulated number)

WITH Pop_vs_Vac (continent, location, date, population, new_vaccinations, PeopleVaccinatedAccumulated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location
	ORDER BY dea.location, dea.date) as PeopleVaccinatedAccumulated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, (PeopleVaccinatedAccumulated/population)*100 as PercentVaccinatedAccum
FROM Pop_vs_Vac

-- Using temp table to find percent of population vaccinated (accumulated number)

-- Note: PeopleVaccinatedAccumulated should actually be doses given accumulated.
-- PercentVaccinatedAccum is inaccurate because it counts all doses including
-- people who only got 1 dose, 2 doses, or 3 doses.

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
PeopleVaccinatedAccumulated numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location
	ORDER BY dea.location, dea.date) as PeopleVaccinatedAccumulated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (PeopleVaccinatedAccumulated/population)*100 as PercentVaccinatedAccum
FROM #PercentPopulationVaccinated

-- Creating view PercentPopulationVaccinated to store data for later visualizations

DROP VIEW if exists PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location
	ORDER BY dea.location, dea.date) as PeopleVaccinatedAccumulated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

-- Viewing data from view PercentPopulationVaccinated

SELECT *
FROM PercentPopulationVaccinated

-- Creating view ContinentsHighestDeathCount to store data for later visualizations

DROP VIEW if exists ContinentsHighestDeathCount

CREATE VIEW ContinentsHighestDeathCount as
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent

-- Viewing data from view ContinentsHighestDeathCount

SELECT *
FROM ContinentsHighestDeathCount

