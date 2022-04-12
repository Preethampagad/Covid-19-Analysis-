SELECT *
FROM sqlprojects.dbo.CovidDeaths
WHERE continent IS NOT NULL

                                            --DATA EXPLORATION--

-- Data we are going to use 
SELECT continent,location,date,total_cases,new_cases,total_deaths,population
FROM sqlprojects.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY continent,location,date



--Calculating death_percentage in India 
SELECT continent,location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as death_percentage
FROM sqlprojects.dbo.CovidDeaths
WHERE location like '%India%' AND continent IS NOT NULL
ORDER BY continent,location,date



--Calculating percentage of population affected in india
SELECT continent,location,date,total_cases,population,(total_cases/population)*100 as per_of_pop_affected_india
FROM sqlprojects.dbo.CovidDeaths
WHERE location like '%India%'
ORDER BY continent,location,date



--Calculating percentage of population affected in the world
SELECT continent,location,date,total_cases,population,(total_cases/population)*100 as per_of_pop_affected
FROM sqlprojects.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY continent,location,date



--Finding the country with highest Percentage of population infected
SELECT continent,location,MAX(total_cases) as highest_no_cases,population,MAX((total_cases/population)*100) as Percentage_of_pop_infected
FROM sqlprojects.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent,location,population
ORDER BY Percentage_of_pop_infected DESC


--Finding the country with highest Percentage of population infected by date
SELECT location,CAST(date AS DATE) as date,MAX(total_cases) as highest_no_cases,population,MAX((total_cases/population)*100) as Percentage_of_pop_infected
FROM sqlprojects.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population,date
ORDER BY Percentage_of_pop_infected DESC



--Calculating highest death count
SELECT location,MAX(CAST(total_deaths AS INT)) as highest_no_deaths,population,MAX((total_deaths/population)*100) as death_rate
FROM sqlprojects.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent,location,population
ORDER BY highest_no_deaths DESC



-- Calculating Highest death count by continent
SELECT continent,MAX(CAST(total_deaths AS INT)) as death_counts,MAX((total_deaths/population)*100) as death_percentage
FROM sqlprojects.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent 
ORDER BY death_counts DESC

--Total DeathCount
SELECT location,SUM(CAST(new_deaths AS INT)) as TotalDeathCount
FROM sqlprojects.dbo.CovidDeaths
WHERE continent IS NULL 
and location NOT IN ('World','Intenational','Low income','European Union','High income','Lower middle income','Upper middle income','International')
GROUP BY location
ORDER BY TotalDeathCount Desc



--GLOBAL Death_percentage by each day
SELECT date,SUM(new_cases) as Total_Cases, SUM(CAST(new_deaths AS INT)) AS Total_deaths, 
(SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS death_percentage
FROM  sqlprojects.dbo.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY date



--GLOBAL Death_percentage
SELECT SUM(new_cases) as Total_Cases, SUM(CAST(new_deaths AS INT)) AS Total_deaths, 
(SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS death_percentage
FROM  sqlprojects.dbo.CovidDeaths
WHERE continent IS NOT NULL



--Total number of people vaccinated (rolling_total_vaccination)
SELECT d.continent,d.location,d.date,d.population,v.new_vaccinations
,SUM(CONVERT(BIGINT,v.new_vaccinations))OVER(PARTITION BY d.location ORDER BY d.location,d.date) AS rolling_total_vaccinations
FROM sqlprojects.dbo.CovidDeaths as d
JOIN sqlprojects.dbo.CovidVaccinations AS v
ON d.location=v.location and d.date=v.date
WHERE d.continent IS NOT NULL AND v.new_vaccinations is not null
ORDER BY d.location,d.date



--Total number of people vaccinated using CTE
--Number Of columns in CTE should be Equal to Number of columns in the table
--Order by should not be used inside 
--We should run along with CTE
WITH PopVSVacc (Continent,location,date,population,new_vaccinations, rolling_total_vaccinations)
AS 
(
SELECT d.continent,d.location,d.date,d.population,v.new_vaccinations
,SUM(CONVERT(BIGINT,v.new_vaccinations))OVER(PARTITION BY d.location ORDER BY d.location,d.date) AS rolling_total_vaccinations
FROM sqlprojects.dbo.CovidDeaths as d
JOIN sqlprojects.dbo.CovidVaccinations AS v
ON d.location=v.location and d.date=v.date
WHERE d.continent IS NOT NULL AND v.new_vaccinations is not null
--ORDER BY d.location,d.date
)
SELECT *,rolling_total_vaccinations/population*100 as perc_of_people_Vacc
FROM PopVsVacc



--Total number of people vaccinated using Temp table
DROP TABLE IF EXISTS #Percentage_of_people_Vaccinated  /*it is required if we want to update temp table */
CREATE TABLE #Percentage_of_people_Vaccinated
(Continent varchar(255),
location varchar(255),
date datetime,
population numeric,
new_vaccinations numeric, 
rolling_total_vaccinations numeric
)
INSERT INTO #Percentage_of_people_Vaccinated
SELECT d.continent,d.location,d.date,d.population,v.new_vaccinations
,SUM(CONVERT(BIGINT,v.new_vaccinations))OVER(PARTITION BY d.location ORDER BY d.location,d.date) AS rolling_total_vaccinations
FROM sqlprojects.dbo.CovidDeaths as d
JOIN sqlprojects.dbo.CovidVaccinations AS v
ON d.location=v.location and d.date=v.date
WHERE d.continent IS NOT NULL AND v.new_vaccinations is not null
--ORDER BY d.location,d.date


SELECT *,rolling_total_vaccinations/population*100 as perc_of_people_Vacc
FROM #Percentage_of_people_Vaccinated

----Total doeses of Covid Vaccines administered by location
SELECT location,population,MAX(rolling_total_vaccinations) AS totalvaccinations
FROM #Percentage_of_people_Vaccinated
GROUP BY location,population
ORDER BY totalvaccinations DESC


--Creating View for Visualization

CREATE VIEW Percentage_people_Vaccinated AS 
SELECT d.continent,d.location,d.date,d.population,v.new_vaccinations
,SUM(CONVERT(BIGINT,v.new_vaccinations))OVER(PARTITION BY d.location ORDER BY d.location,d.date) AS rolling_total_vaccinations
FROM sqlprojects.dbo.CovidDeaths as d
JOIN sqlprojects.dbo.CovidVaccinations AS v
ON d.location=v.location and d.date=v.date
WHERE d.continent IS NOT NULL AND v.new_vaccinations is not null
--ORDER BY d.location,d.date
SELECT *
FROM Percentage_people_Vaccinated
