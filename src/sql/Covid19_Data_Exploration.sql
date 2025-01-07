-- We start with some key information of the disease in my country
Select location, date, total_cases, new_cases, total_deaths, population
From coviddeaths
where location = 'Vietnam'
Order by date;

-- Looking at total cases vs total death
-- What is the likelihood of dying if you contract the covid
-- In my country
Select location, date, total_cases, total_deaths, ROUND(((total_deaths / total_cases) * 100)::numeric, 3) AS DeathPercentage
From coviddeaths
Where location = 'VietName'
Order by date;

-- Overall likelihood through countries
Select location, Round((sum(new_deaths) / sum(new_cases) *100)::numeric, 3) as DeathPercentage
From coviddeaths
Group By location
Having Round((sum(new_deaths) / sum(new_cases) *100)::numeric, 3) IS NOT NULL
Order By DeathPercentage DESC;

-- Looking at total_cases vs population

Select location, date, total_cases, population, ROUND(((total_cases / population) * 100)::numeric, 3) AS PercentageofGetCovid
From coviddeaths
Where location = 'Vietnam'
Order By location, date;

SELECT location, 
       population,
	   Max(total_cases) as HighestTotalCases,
       ROUND(((SUM(new_cases) / population) * 100)::numeric, 3) AS PercentageofGetCovid
FROM coviddeaths
GROUP BY location, population
HAVING ROUND(((SUM(new_cases) / population) * 100)::numeric, 3) IS NOT NULL
ORDER BY PercentageofGetCovid DESC;


--Countries with highest death count compared to population
SELECT 
    location,
    population,
    MAX(total_deaths) AS HighestDeathCount,
    ROUND((MAX(total_deaths) / population * 100)::numeric, 3) AS DeathPercentagebyPopulation
FROM coviddeaths
GROUP BY location, population
HAVING MAX(total_deaths) IS NOT NULL
Order by HighestDeathCount DESC, DeathPercentagebyPopulation DESC;

-- Find more informations about different continents
SELECT continent, MAX(total_cases) AS TotalCases, MAX(total_deaths) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Looking though total cases in the world

SELECT 
    date, 
    SUM(new_cases) AS TotalCases, 
    SUM(new_deaths) AS TotalDeaths, 
    ROUND(
        CASE 
            WHEN SUM(new_cases) = 0 THEN NULL  -- or 0, or 'NaN' if you prefer
            ELSE (SUM(new_deaths) / SUM(new_cases)) * 100
        END::numeric, 
        3
    ) AS DeathPercentage
FROM coviddeaths
GROUP BY date
ORDER BY date;


SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths, ROUND(((SUM(cast(new_deaths AS int))/SUM(new_cases))*100)::numeric, 2) AS DeathPercentage
FROM coviddeaths
WHERE continent is NOT NULL
ORDER BY 1,2;


-- Looking at total population vs Vaccinations
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
From coviddeaths cd
Join covidvaccinations cv ON cv.location = cd.location and cv.date = cd.date
Where cd.location = 'Vietnam'
Order by 2,3;

--Calculate the rolling people vacinated percentage

WITH VaccinatedInfo as(
	Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
	From coviddeaths cd
	Join covidvaccinations cv ON cv.location = cd.location and cv.date = cd.date
	Where cd.location = 'Vietnam'
	Order By 2,3
)

Select *, Round((RollingPeopleVaccinated/population)*100::numeric, 2) AS RollingVacinatedPercentage
From VaccinatedInfo;

-- Calculate total number of vaccinations in a country
Select cd.location, cd.continent, cd.population, Max(total_vaccinations) as total_vaccinations,  MAX(cd.total_deaths) AS total_deaths
From covidvaccinations cv
Join coviddeaths cd on cv.location = cd.location and cv.date = cd.date
Group by cd.location, cd.continent, cd.population
Having Max(total_vaccinations) IS NOT NULL
Order by total_vaccinations DESC;

-- Analyze the correlation between GDP per capita and vaccination rates.
SELECT location, gdp_per_capita, MAX(people_vaccinated_per_hundred) AS vaccination_rate
FROM CovidVaccinations
Where gdp_per_capita IS NOT NULL
GROUP BY location, gdp_per_capita
Having  Max(people_vaccinated_per_hundred) IS NOT NULL
ORDER BY gdp_per_capita DESC;

-- Find the effect of population density on vaccination rates.

SELECT location, population_density, MAX(people_vaccinated_per_hundred) AS vaccination_rate
FROM CovidVaccinations
GROUP BY location, population_density
ORDER BY population_density DESC;

-- Calculate the average vaccination rate per continent.

SELECT continent, AVG(total_vaccinations_per_hundred) AS avg_vaccination_rate
FROM CovidVaccinations
WHERE continent IS NOT NULL
GROUP BY continent;



