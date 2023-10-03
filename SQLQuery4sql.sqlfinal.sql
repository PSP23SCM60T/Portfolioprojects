select *
from [sql portfolio]..coviddeaths
order by 3,4

select *
from [sql portfolio]..['covidvaccinations$']
order by 3,4

select location,date, total_cases,new_cases,total_deaths, population
from [sql portfolio]..coviddeaths
order by date,location

select location,date, total_cases,total_deaths, (total_deaths/total_cases)
from [sql portfolio]..coviddeaths
order by date,location

--looking at total deaths vs total cases
SELECT location, date, convert(float,total_cases) as total_cases,convert(float,total_deaths) as total_deaths,
case 
    when total_cases = 0 then NULL
	else CONVERT(float,total_deaths)/CONVERT(float,total_cases)*100
end  as deathrate
FROM [sql portfolio]..coviddeaths
where location like 'india'
ORDER BY location,date;

--lokking at total cases vs population
SELECT location, date, convert(float,total_cases) as total_cases,population,
case 
    when total_cases = 0 then NULL
	else CONVERT(float,total_cases)/population *100
end  as deathrate
FROM [sql portfolio]..coviddeaths
where location like 'india'
ORDER BY location,date;

--looking at countries with highest infection rate

SELECT location, max(convert(float,total_cases)) as highestinfectedcount,population,
case 
    when max(total_cases) = 0 then NULL
	else max(CONVERT(float,total_cases)/population )*100
end as percentageofpopulationinfected
FROM [sql portfolio]..coviddeaths
group by location,population
ORDER BY percentageofpopulationinfected desc;
 -- looking at countries with highest death count
 
SELECT location, max(convert(float,total_deaths)) as totaldeathcounrt,population,
case 
    when max(total_deaths) = 0 then NULL
	else max(CONVERT(float,total_deaths)/population )*100
end as percentageofdead
FROM [sql portfolio]..coviddeaths
--where location like '%india%'
where continent is not null
group by location,population
ORDER BY totaldeathcounrt desc;

select *
from [sql portfolio]..coviddeaths
where continent is not null
order by 3,4

--lets breakdown things by locatio and more accurate
SELECT location, max(convert(float,total_deaths)) as totaldeathcount
FROM [sql portfolio]..coviddeaths
--where location like '%india%'
where continent is null
group by location
ORDER BY totaldeathcount desc;

--lets break things down by continent
select continent,max(convert(float,total_deaths)) as totaldeathcount
from [sql portfolio]..coviddeaths
where continent is not null
 group by continent
 order by totaldeathcount desc;

 -- Global Numbers
 select date,
 SUM(convert(float,new_cases)) as totalcases,
 sum(convert(float,new_deaths)) as total_dead,
 sum(convert(float,new_deaths))/sum(convert(float,new_cases))*100 as deathpercentage
  from[sql portfolio]..coviddeaths
  where continent is not null
 group by date
 order by 1,2
 --chatgpt
 SELECT
    date,
    SUM(new_cases) AS totalcases,
    SUM(new_deaths) AS total_dead,
    SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 AS deathpercentage
FROM [sql portfolio]..coviddeaths
where continent is not null
GROUP BY date
ORDER BY 1,2;
--over all across the world
SELECT
    SUM(new_cases) AS totalcases,
    SUM(new_deaths) AS total_dead,
    SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 AS deathpercentage
FROM [sql portfolio]..coviddeaths
where continent is not null
--GROUP BY date
ORDER BY 1,2;

--looking at total population vs vaccinations

select d.location,d.date,d.population,v.new_vaccinations
from [sql portfolio]..coviddeaths d
join [sql portfolio]..['covidvaccinations$'] v
on d.location= v.location 
and d.date =v.date
where d.continent is not null
and d.population is not null
and d.location like '%states%'
order by location,date

--same with counting total number of vaccinations done in each country
select d.location,d.date,d.population,v.new_vaccinations,
SUM(convert(float, v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as rollingpeoplevaccinated
from [sql portfolio]..coviddeaths d
join [sql portfolio]..['covidvaccinations$'] v
on d.location= v.location 
and d.date =v.date
where d.continent is not null
and d.population is not null
and d.location like '%india%'
order by location,date

--same with counting total number of vaccinations done in each country and percentage of vaccinations done vs population
select d.location,d.date,d.population,v.new_vaccinations,
SUM(convert(float, v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as rollingpeoplevaccinated,
--(rollingpeoplevaccinated/population)*100
--didm't work had an error so shd we shd use CTE or Temp tables
from [sql portfolio]..coviddeaths d
join [sql portfolio]..['covidvaccinations$'] v
on d.location= v.location 
and d.date =v.date
where d.continent is not null
and d.population is not null
and d.location like '%india%'
order by location,date

 
 --use CTE
 with pvsv(continent,location,date,population,new_vaccinations,rollingpeoplevaccinated)
 as
 (
 select d.continent, d.location,d.date,d.population,v.new_vaccinations,
SUM(convert(float, v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/population)*100
--didm't work had an error so shd we shd use CTE or Temp tables
from [sql portfolio]..coviddeaths d
join [sql portfolio]..['covidvaccinations$'] v
on d.location= v.location 
and d.date =v.date
where d.continent is not null
and population is not null
and d.location like '%states%'
--order by location,date
)
select *, (rollingpeoplevaccinated/population)*100
from pvsv


--Temp table
drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)
insert into #percentpopulationvaccinated
select d.continent, d.location,d.date,d.population,v.new_vaccinations,
SUM(convert(float, v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/population)*100
--didm't work had an error so shd we shd use CTE or Temp tables
from [sql portfolio]..coviddeaths d
join [sql portfolio]..['covidvaccinations$'] v
on d.location= v.location 
and d.date =v.date
--where d.continent is not null
--and population is not null
and d.location like '%states%'
--order by location,date

select *,(rollingpeoplevaccinated/population)*100
from #percentpopulationvaccinated


 create view #percentpopulationvaccinated
 as
 select d.continent, d.location,d.date,d.population,v.new_vaccinations,
SUM(convert(float, v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/population)*100
--didm't work had an error so shd we shd use CTE or Temp tables
from [sql portfolio]..coviddeaths d
join [sql portfolio]..['covidvaccinations$'] v
on d.location= v.location 
and d.date =v.date
--where d.continent is not null
--and population is not null
and d.location like '%states%'
--order by location,date
select*
from #percentpopulationvaccinated
