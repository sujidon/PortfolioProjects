----looking at death percentage
----shows the likelihood of dying if you contract covid in your country

--SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
--from [Portfolio Project]..CovidDeaths
--WHERE location like '%kenya%'
--order by 1,2

------looking at total cases vs population
----shows what percentage of the population is infected
--SELECT location, date, total_cases, new_cases,population, (total_cases/ population)*100 as PercentInfected
--from [Portfolio Project]..CovidDeaths
--WHERE location like '%kenya%'
--order by 1,2

----looking at countries with highest infection rate compared to population

--SELECT location,population,MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100
--as PercentagePopulationInfected
--from [Portfolio Project]..CovidDeaths
--Group by location, population
--order by 4 desc

----now to check the totaldeathcount per country
----there will be need to change the data type of total deaths to int 
----there will be need to remove continents with null

--SELECT location,MAX (cast(total_deaths as int)) as TotalDeathCount
--from [Portfolio Project]..CovidDeaths
--where continent is not null
--Group by location
--Order by TotalDeathCount DESC

------now to check the totaldeathcount per continent
----based on how the original excel file was created, continent rows are found as totals under location

--SELECT location,MAX (cast(total_deaths as int)) as TotalDeathCount
--from [Portfolio Project]..CovidDeaths
--where continent is null
--Group by location
--Order by TotalDeathCount DESC

----but for the sake of follow up, let us have the query as it should be

--SELECT continent, MAX (cast(total_deaths as int)) as TotalDeathCount
--from [Portfolio Project]..CovidDeaths
--where continent is not null
--Group by continent
--Order by TotalDeathCount DESC

----lets look at global numbers, eg the total number of new cases per day and total deaths
--SELECT 
--	date, 
--	sum(new_cases) as NewCasesPerDay, 
--	sum(cast(new_deaths as int)) as NewDeathsPerDay,
--	sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentagePerDay
--from [Portfolio Project]..CovidDeaths
--where continent is not null
--Group by date
--order by 1,2

------for the entire period in the world

----SELECT 
----	sum(new_cases) as NewCasesPerDay, 
----	sum(cast(new_deaths as int)) as NewDeathsPerDay,
----	sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentagePerDay
----from [Portfolio Project]..CovidDeaths
----where continent is not null
----order by 1,2

--------now lets incoorperate vaccination data

------select *
------from [Portfolio Project]..CovidDeaths dea
------join [Portfolio Project]..CovidVaccinations vac
------	on dea.location= vac.location
------	and dea.date=vac.date

--------lets look at total population vs total vaccination
----select 
----	dea.continent,
----	dea.location,
----	dea.population,
----	dea.date,
----	vac.new_vaccinations,
----	sum(convert(int,vac.new_vaccinations))over (partition by dea.location ) NewVaccinations
----from [Portfolio Project]..CovidDeaths dea
----join [Portfolio Project]..CovidVaccinations vac
----	on dea.location= vac.location
----	and dea.date=vac.date
----where dea.continent is not null
----order by 1,2,3

----now the problem with the query above is that we are not able to see how the new vaccinations are being added cummulatively for a particular country per day
----we can only see the total value of new vaccinations for the entire period which has been appended to each day which is wrong
----to solve this, we need to order our partition to ensure it partitions per day for every location
----we'll add (order by dea.location,dea.date) to the partition by statement
----this wil give us 347702 total in the last day of Albania as should be the case
----when partitioning, it is always important to ORDER YOUR PARTITION!!
--select 
--	dea.continent,
--	dea.location,
--	dea.population,
--	dea.date,
--	vac.new_vaccinations,
--	sum(convert(int,vac.new_vaccinations))over (partition by dea.location order by dea.location, dea.date) NewVaccinations
--from [Portfolio Project]..CovidDeaths dea
--join [Portfolio Project]..CovidVaccinations vac
--	on dea.location= vac.location
--	and dea.date=vac.date
--where dea.continent is not null
--order by 1,2,3
--we can calculate percentages at each point and see how the percentage vaccincated gradually increased for a particular location
--let's try Israel

select 
	dea.continent,
	dea.location,
	dea.population,
	dea.date,
	dea.total_cases,
	dea.total_deaths,
	vac.new_vaccinations,
	sum(convert(int,vac.new_vaccinations))over (partition by dea.location order by dea.location, dea.date) NewVaccinations,
	sum(convert(int,vac.new_vaccinations))over (partition by dea.location order by dea.location, dea.date)/population*100 as PercentageVaccinated
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
	on dea.location= vac.location
	and dea.date=vac.date
where dea.continent is not null and dea.location like '%Kenya%'
order by dea.date

----NOW, GROUPING BY LOCATION
----it would also be needfull to do some find the percentage vaccinated in every location
----this is possible by dividing TotalVaccinations with population
----the previous query will provide the source data for our calculations and therefore act as a subquery
----the outer query, which will dictate our final output can be as follows
------select 
------	max(dea.continent) as continent,(For us to include continent in the group)
------    dea.location,
------    dea.population,
------    sum(convert(int, dea.new_vaccinations)) as NewVaccinations,(we don't need to partition since we've already done that in the subquery)
------	sum(convert(int, dea.new_vaccinations))/population*100 as PercentageVaccinated
------from 
------(SUBQUERY)as dea
------group by dea.location, dea.population
------order by 2 

select 
	max(dea.continent) as continent,
    dea.location,
    dea.population,
	dea.gdp_per_capita,
	sum(convert(int,dea.total_deaths)) as TotalDeaths,
    sum(convert(int, dea.new_vaccinations)) as NewVaccinations,
	sum(convert(int, dea.new_vaccinations))/population*100 as PercentageVaccinated
from (
    select 
	dea.continent,
	dea.location,
	dea.population,
	dea.total_cases,
	dea.total_deaths,
	vac.gdp_per_capita,
    vac.new_vaccinations,
	sum(convert(int,vac.new_vaccinations))over (partition by dea.location order by dea.location, dea.date) NewVaccinations,
	sum(convert(int,dea.total_deaths))over (partition by dea.location order by dea.location, dea.date) TotalDeaths
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
	on dea.location= vac.location
	and dea.date=vac.date
where dea.continent is not null

) dea
group by 
	dea.location,
    dea.population,
	dea.gdp_per_capita

order by 5 DESC

--Let's use CTE for the previous query

with PopVsVac as 
(
select 
	dea.continent,
	dea.location,
	dea.population,
	dea.total_cases,
	dea.total_deaths,
	vac.gdp_per_capita,
    vac.new_vaccinations,
	sum(convert(int,vac.new_vaccinations))over (partition by dea.location order by dea.location, dea.date) NewVaccinations,
	sum(convert(int,dea.total_deaths))over (partition by dea.location order by dea.location, dea.date) TotalDeaths
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
	on dea.location= vac.location
	and dea.date=vac.date
where dea.continent is not null
)
select
max(continent) as continent,
    location,
    population,
	gdp_per_capita,
	sum(convert(int,total_deaths)) as TotalDeaths,
    sum(convert(int,new_vaccinations)) as NewVaccinations,
	sum(convert(int,new_vaccinations))/population*100 as PercentageVaccinated

from PopVsVac
group by 
	location,
    population,
	gdp_per_capita

--using TEMP TABLE
--note** for some strange reason, gdp column won't create
Drop table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
population numeric,
total_cases numeric,
total_deaths numeric,
new_vaccinations numeric,
NewVaccinations numeric,
TotalDeaths numeric,
)
insert into #PercentPopulationVaccinated
(
continent,
location,
population,
total_cases,
total_deaths,
new_vaccinations,
NewVaccinations,
TotalDeaths
)
select 
	dea.continent,
	dea.location,
	dea.population,
	dea.total_cases,
	dea.total_deaths,
    vac.new_vaccinations,
	sum(convert(int,vac.new_vaccinations))over (partition by dea.location order by dea.location, dea.date) NewVaccinations,
	sum(convert(int,dea.total_deaths))over (partition by dea.location order by dea.location, dea.date) TotalDeaths
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
	on dea.location= vac.location
	and dea.date=vac.date
where dea.continent is not null

select
max(continent) as continent,
    location,
    population,
	sum(convert(int,total_deaths)) as TotalDeaths,
    sum(convert(int,new_vaccinations)) as NewVaccinations,
	sum(convert(int,new_vaccinations))/population*100 as PercentageVaccinated

from  #PercentPopulationVaccinated
group by 
	location,
    population

--using VIEWS

Create View PercentPopulationVaccinated as
select 
	dea.continent,
	dea.location,
	dea.population,
	dea.total_cases,
	dea.total_deaths,
	vac.gdp_per_capita,
    vac.new_vaccinations,
	sum(convert(int,vac.new_vaccinations))over (partition by dea.location order by dea.location, dea.date) NewVaccinations,
	sum(convert(int,dea.total_deaths))over (partition by dea.location order by dea.location, dea.date) TotalDeaths
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
	on dea.location= vac.location
	and dea.date=vac.date
where dea.continent is not null

--you can query from that view i.e grouping by 
select
max(continent) as continent,
    location,
    population,
	gdp_per_capita,
	sum(convert(int,total_deaths)) as TotalDeaths,
    sum(convert(int,new_vaccinations)) as NewVaccinations,
	sum(convert(int,new_vaccinations))/population*100 as PercentageVaccinated

from PercentPopulationVaccinated
group by 
	location,
    population,
	gdp_per_capita