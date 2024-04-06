select * from portaforlioproject.coviddeaths
where continent is not null
order by 3,4;

#select *
#from portaforlioproject.covidvaccination
#order by 3,4;

#select data that we are going to be using
select Location, date, total_cases, new_cases, total_deaths, population
from portaforlioproject.coviddeaths
where continent is not null
order by 1,2;

#looking at total cases vs total deaths
#show likelihood of dying if you contract covid in you country
select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from portaforlioproject.coviddeaths
where location like "%Costa%"
order by 1,2;

#looking at total cases vs population
#show what percentage of population infected with covid
select Location, date, total_cases, population, (total_cases/population)*100 as percentage_population_infected
from portaforlioproject.coviddeaths
#where location like "%Costa%"
order by 1,2;

#countries with highest infection rate compared to population
select location, population, max(total_cases) as highest_infection_count, max((total_cases/population))*100 as percent_population_infected
from portaforlioproject.coviddeaths
#where location like "%Costa%"
group by location, population
order by percent_population_infected desc;

#countries with highest death number per population
select location, max(total_deaths) as total_death_count
from portaforlioproject.coviddeaths
where continent is not null
#and location like "%Costa%"
group by location
order by total_death_count desc;

#breaking things down by continent
#showing continent whit the highes death count per population
select continent, max(total_deaths) as total_death_count
from portaforlioproject.coviddeaths
where continent is not null
#and continent like "%Costa%"
group by continent
order by total_death_count desc;

#global numbers
select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as death_percentage
from portaforlioproject.coviddeaths
where continent is not null
order by 1,2;

#total population vs vaccinations
#shows percentage of population that had recived at least one covid vaccine
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
#(rolling_people_vaccinated/population)*100 as percentage_population_vaccinated
from portaforlioproject.coviddeaths dea
join portaforlioproject.covidvaccination vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
#and dea.location like "%Costa%"
order by 2,3;

#using cte to perform calculation onpartition byprevious query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, rolling_people_vaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as Rolling_people_Vaccinated
From portaforlioproject.coviddeaths dea
Join portaforlioproject.covidvaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (rolling_people_vaccinated/population)*100
From PopvsVac;

#Using Temp Table to perform Calculation on Partition By in previous query
use portaforlioproject;
DROP TEMPORARY TABLE IF EXISTS percent_population_vaccinated;

CREATE TEMPORARY TABLE percent_population_vaccinated (
    Continent CHAR(255) CHARACTER SET UTF8MB4,
    Location CHAR(255) CHARACTER SET UTF8MB4,
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    rolling_people_vaccinated DECIMAL(18,2)
);

INSERT INTO percent_population_vaccinated
SELECT dea.continent, dea.location, STR_TO_DATE(dea.date, '%d/%m/%Y'), dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS rolling_people_vaccinated
FROM portaforlioproject.coviddeaths dea
JOIN Portaforlioproject.covidvaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

SELECT 
    Continent,
    Location,
    Date,
    Population,
    New_vaccinations,
    rolling_people_vaccinated,
    (SUM(New_vaccinations) OVER (PARTITION BY Location ORDER BY Location, Date) / Population) * 100 AS percent_population_vaccinated
FROM percent_population_vaccinated;
#LIMIT 0, 1000

#Creating View to store data for later visualizations
Create View percent_population_vaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_people_vaccinated
From portaforlioproject.coviddeaths dea
Join portaforlioproject.covidvaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null;
SELECT * FROM portaforlioproject.percent_population_vaccinated;