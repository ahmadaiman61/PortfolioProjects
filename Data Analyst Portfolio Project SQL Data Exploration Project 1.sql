SELECT * 
FROM PortfolioProject..CovidDeaths
where total_deaths = '576232'
order by 3,4

select * from PortfolioProject..CovidVaccinations
order by 3,4

select Location, date, total_cases, total_deaths,
(total_deaths/total_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths
where continent is not null
and location like '%malaysia%'
order by 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

select Location, population, MAX(total_cases) as HighestInfectionCount,
(MAX(total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
where continent is not null
group by Location, population
order by 4 desc

--Showing countries with highest death count per population

select Location, MAX(cast(total_deaths as int)) as HighestDeath
FROM PortfolioProject..CovidDeaths
where continent is not null
group by Location
order by 2 desc

--Showing continents with highest death count per population

select continent, MAX(cast(total_deaths as int)) as HighestDeath
FROM PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by 2 desc

-- GLOBAL NUMBERS

select date, SUM(new_cases) as totalnewcases, sum(cast(new_deaths as int)) as
totalnewdeath, sum(cast(new_deaths as int))/SUM(new_cases)*100 as deathpercent
FROM PortfolioProject..CovidDeaths
where continent is not null
GROUP BY date
order by 4 desc

--Looking at Total Population vs Vaccinations

select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) over
(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
AND vac.new_vaccinations IS NOT NULL
order by RollingPeopleVaccinated asc

-- USE CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #PercentPopulationVaccinated
	SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL

SELECT 
    *,
    (RollingPeopleVaccinated/population)*100 as vacpercent 
FROM 
    #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

create view PercentPopulationVaccinated as
	SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL