# DataCamp INTERMEDIATE SQL 

## Count and distinct 

SELECT COUNT(country) AS count_country FROM films; 

SELECT COUNT(film_id) AS count_film_id
FROM reviews;

SELECT COUNT(birthdate) AS count_birthdate, COUNT(name) AS count_names FROM people; 

SELECT COUNT(DISTINCT language) AS distinct_count_language FROM films; 

SELECT COUNT(language) AS count_languages, COUNT(country) AS count_countries
FROM films;

## Debugging 

-- Debug this code
SELECT certification
FROM films
LIMIT 5;

-- answer 
SELECT films.certification
FROM films
LIMIT 5;

-- Debug this code
SELECT film_id imdb_score num_votes
FROM reviews;

-- answer
SELECT film_id, imdb_score, num_votes
FROM reviews;

-- Debug this code
SELECT COUNNT(birthdate) AS count_birthdays
FROM peeple;

-- answer 
SELECT COUNT(birthdate) AS count_birthdays
FROM people;

## Best practices 

https://www.sqlstyle.guide/ 

-- Rewrite this query
select person_id, role from roles limit 10


-- answer 
SELECT person_id, role
FROM roles
LIMIT 10; 

## Filtering numbers 

-- Select film_ids and imdb_score with an imdb_score over 7.0
- answer

SELECT reviews.film_id, reviews.imdb_score
FROM reviews
WHERE imdb_score > 7.0; 

-- Select film_ids and facebook_likes for ten records with less than 1000 likes 
- answer 
SELECT reviews.film_id, reviews.facebook_likes
FROM reviews
WHERE facebook_likes < 1000
LIMIT 10; 

-- Count the records with at least 100,000 votes
- answer 
SELECT COUNT(num_votes) AS films_over_100K_votes
FROM reviews
WHERE num_votes > 100000; 

-- Count the Spanish-language films
- answer 
SELECT COUNT(language)AS count_spanish
FROM films
WHERE language = 'Spanish';

## Multiple criteria filter 

-- Select the title and release_year for all German-language films released before 2000
- answer 
SELECT films.title, films.release_year
FROM films
WHERE language = 'German' 
AND release_year < 2000; 

-- Update the query to see all German-language films released after 2000
- answer 
SELECT title, release_year
FROM films
WHERE release_year > 2000
AND language = 'German';
	
-- Select all records for German-language films released after 2000 and before 2010	
- answer 
SELECT *
FROM films
WHERE release_year > 2000
AND release_year < 2010
AND language = 'German';


-- Find the title and year of films from the 1990 or 1999, which were in English or Spanish and took in more than $2,000,000 gross.
- answer 
SELECT title, release_year
FROM films
WHERE (release_year = 1990 OR release_year = 1999)
AND (language = 'English' OR language = 'Spanish')
AND (gross > 2000000);

-- Select the title and release_year for films released between 1990 and 2000 with Spanish-language or French-language films with budgets over $100 million.
- answer 
SELECT title, release_year
FROM films
WHERE release_year BETWEEN 1990 AND 2000
AND budget > 100000000
AND (language = 'Spanish' OR language = 'French');


## Filtering text 

-- Select the names that start with B
- answer 
SELECT names
FROM people
WHERE name LIKE 'B%';

--Select the names of people whose names have 'r' as the second letter. 
- answer 
SELECT name
FROM people
WHERE name LIKE '_r%';
--Select the names of people whose names don't start with 'A'. 
- answer 
SELECT name
FROM people
WHERE name NOT LIKE 'A%'; 

-- Find the title and release_year for all films over two hours in length released in 1990 and 2000
- answer 
SELECT title, release_year
FROM films
WHERE release_year IN(1990, 2000)
AND duration > 120; 

-- Find the title and language of all films in English, Spanish, and French
SELECT title, language
FROM films
WHERE language IN('English', 'Spanish', 'French');

-- Find the title, certification, and language all films certified NC-17 or R that are in English, Italian, or Greek
- answer 
SELECT title, certification, language
FROM films
WHERE certification IN('NC-17', 'R')
AND language IN('English', 'Italian', 'Greek'); 

-- Count the unique titles
- answer 
SELECT COUNT(DISTINCT title) AS nineties_english_films_for_teens
FROM films
WHERE release_year BETWEEN 1990 AND 1999
AND language = 'English'
AND certification IN('G', 'PG', 'PG-13');

## Null 

-- List all film titles with missing budgets
- answer 
SELECT title AS no_budget_info 
FROM films
WHERE budget ISNULL; 

-- Count the number of films we have language data for
- answer 
SELECT COUNT(title) AS count_language_known
FROM films
WHERE language IS NOT NULL; 

## Summarizing data 

-- Query the sum of film durations
- answer 
SELECT SUM(duration) AS total_duration 
FROM films; 

-- Calculate the average duration of all films
- answer 
SELECT AVG(duration) AS average_duration 
FROM films; 

-- Find the latest release_year
- answer 
SELECT max(release_year) AS latest_year
FROM films; 


-- Find the duration of the shortest film
- answer 
SELECT MIN(duration) as shortest_film
FROM films; 