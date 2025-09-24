/*

ANALYSING STUDENTS' MENTAL HEALTH 

*/


-- DATA PROCESSING, CLEANING AND MANIPULATION
-- Staging

CREATE TABLE students_info_staging 
LIKE mental_health;

INSERT students_info_staging
SELECT *
FROM mental_health;

SELECT *
FROM students_info_staging;

----------------------------------------------------------------------------------------------------------------------------------------------
-- Identifying and removing duplicate records
-- Step 1. Identifying row numbers

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY inter_dom, region, gender, academic, age, stay, stay_cate) AS row_num
FROM students_info_staging;

-- Step 2. Identifying duplicate rows using a CTE

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY inter_dom, region, gender, academic, age, stay, stay_cate, age, phone_bi) AS row_num
FROM students_info_staging
)

SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Step 3. Checking what will be deleted using a SUBQUERY

DELETE FROM students_info_staging 
WHERE `index` IN (
    SELECT `index` FROM (
        SELECT `index`,
               ROW_NUMBER() OVER(
                   PARTITION BY inter_dom, region, gender, academic, age, stay, stay_cate, phone_bi 
                   ORDER BY `index`
               ) AS row_num
        FROM students_info_staging
    ) AS subquery
    WHERE row_num > 1
);

-- Step 4. Removing duplicates using a WHERE clause

DELETE t FROM students_info_staging AS t
JOIN (
    SELECT `index`,
           ROW_NUMBER() OVER(
               PARTITION BY inter_dom, region, gender, academic, age, stay, stay_cate, phone_bi 
               ORDER BY `index`
           ) AS row_num
    FROM students_info_staging
) AS duplicate_cte ON t.`index` = duplicate_cte.`index`
WHERE duplicate_cte.row_num > 1;


SELECT *
FROM students_info_staging;
----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------
-- Standardize data

-- REPLACE function
UPDATE students_info_staging
SET inter_dom = 'Domestic'
WHERE inter_dom = 'Dom';

UPDATE students_info_staging
SET inter_dom = 'International'
WHERE inter_dom = 'Inter';


UPDATE students_info_staging
SET academic = 'Graduate'
WHERE academic = 'Grad';

UPDATE students_info_staging
SET academic = 'Under graduate'
WHERE academic = 'Under';

select *
from students_info_staging;
----------------------------------------------------------------------------------------------------------------------------------------------
-- TRIM function
SELECT *,
LTRIM(inter_dom)
FROM students_info_staging;


SELECT *,
TRIM(stay_cate)
FROM students_info_staging;

----------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
-- Dealing with NULL or BLANK values
-- Using a COALESCE function.

SELECT COALESCE(intimate, 'Unknown') AS intimate,
	   COALESCE(internet, '0') AS internet
FROM students_info_staging;


-- Using a COALESCE function within the SET clause.

UPDATE students_info_staging
SET intimate = COALESCE(intimate, 'Unknown'),
    internet = COALESCE(internet, '0');

----------------------------------------------------------------------------------------------------------------------------------------------
-- Using a CASE statement to check for whitespaces and address null values

UPDATE students_info_staging
SET intimate = CASE
                   WHEN intimate IS NULL OR TRIM(intimate) = '' THEN 'Unknown'
                   ELSE intimate
               END,
    internet = CASE
                   WHEN internet IS NULL OR TRIM(internet) = '' THEN 'Unknown'
                   ELSE internet
               END;
               
SELECT *
FROM students_info_staging;

----------------------------------------------------------------------------------------------------------------------------------------------
-- Exploratory data analysis
-- Creating age bins

SELECT
    age,
    CASE
        WHEN CAST(age AS SIGNED) >= 15 AND CAST(age AS SIGNED) <= 19 THEN '15-19'
        WHEN CAST(age AS SIGNED) >= 20 AND CAST(age AS SIGNED) <= 24 THEN '20-24'
        WHEN CAST(age AS SIGNED) >= 25 AND CAST(age AS SIGNED) <= 29 THEN '25-29'
        WHEN CAST(age AS SIGNED) >= 30 AND CAST(age AS SIGNED) <= 34 THEN '30-34'
        WHEN CAST(age AS SIGNED) >= 35 THEN '35+'
        ELSE 'Unknown'
    END AS age_group
FROM
    students_info_staging
WHERE
    age IS NOT NULL;   

-------------------------------------------------------------------------------------------------------------------------------------------
-- Creating a new bin column

ALTER TABLE students_info_staging
ADD COLUMN age_group VARCHAR(10);

-- Updating the columns with calculated values

UPDATE students_info_staging
SET age_group = CASE
    WHEN CAST(age AS SIGNED) >= 15 AND CAST(age AS SIGNED) <= 19 THEN '15-19'
    WHEN CAST(age AS SIGNED) >= 20 AND CAST(age AS SIGNED) <= 24 THEN '20-24'
    WHEN CAST(age AS SIGNED) >= 25 AND CAST(age AS SIGNED) <= 29 THEN '25-29'
    WHEN CAST(age AS SIGNED) >= 30 AND CAST(age AS SIGNED) <= 34 THEN '30-34'
    WHEN CAST(age AS SIGNED) >= 35 THEN '35+'
    ELSE 'Unknown'
END;

----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------
-- Descriptive Statistics
-- avg, sum, min, max, count, distinct count

SELECT 
	gender,
	AVG(age) AS avg_age,
	COUNT(gender) AS total_gender,
	ROUND(AVG(tosc), 2) AS avg_social_connectedness ,
	SUM(apd) AS sum_apd,
	MIN(ahome) AS min_ahome,
	MAX(aph) AS max_aph,
	COUNT(DISTINCT region) AS region
FROM students_info_staging
	WHERE gender = 'Male' OR gender = 'Female'
	GROUP BY gender;
    
-- Average scores of depression, social correctness, and acculturative stress levels among international students.

SELECT 
	gender,
	ROUND(AVG(CAST(todep AS SIGNED))) AS avg_dep,
	ROUND(AVG(CAST(tosc AS SIGNED))) AS avg_sc,
	ROUND(AVG(CAST(toas AS SIGNED))) AS avg_as
FROM students_info_staging
	WHERE 
	 todep IS NOT NULL AND
	 tosc IS NOT NULL AND 
	 toas IS NOT NULL  AND
	inter_dom = 'International' AND inter_dom IS NOT NULL 
	GROUP BY gender;

----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------    
-- Frequency Distributions

SELECT gender, age_group, COUNT(age) AS age
FROM students_info_staging
GROUP BY gender, age_group, age
ORDER BY COUNT(age) DESC;


SELECT
    inter_dom AS student_type,
    age_group,
    COUNT(*) AS frequency
FROM
    students_info_staging
GROUP BY
    inter_dom, age_group
ORDER BY
    frequency DESC;
    

SELECT age, gender, parents_bi, parents
FROM students_info_staging
	WHERE gender = 'Male' AND parents_bi = 'Yes'
		ORDER BY age DESC;
        
----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------
-- INFERENTIAL STATISTICS
-- Correlation analysis

SELECT
    -- Correlation between inter_dom and todep
    (COUNT(*) * SUM((inter_dom = 'International') * todep) - SUM(inter_dom = 'International') * SUM(todep)) /
    (SQRT(COUNT(*) * SUM(inter_dom = 'International') - SUM(inter_dom = 'International') * SUM(inter_dom = 'International')) *
     SQRT(COUNT(*) * SUM(todep * todep) - SUM(todep) * SUM(todep))) AS inter_dom_corr,
    
    -- Correlation between gender and todep
    (COUNT(*) * SUM((gender = 'Male') * todep) - SUM(gender = 'Male') * SUM(todep)) /
    (SQRT(COUNT(*) * SUM(gender = 'Male') - SUM(gender = 'Male') * SUM(gender = 'Male')) *
     SQRT(COUNT(*) * SUM(todep * todep) - SUM(todep) * SUM(todep))) AS gender_corr
FROM students_info_staging
WHERE inter_dom IN ('International', 'Domestic')
AND gender IN ('Male', 'Female');

-------------------------------------------------------------------------------------------------------------------------------------------------

	-- Correlation between depression and social connectedness
SELECT
	(COUNT(*) * SUM(tosc * todep) - SUM(tosc) * SUM(todep)) /
	(SQRT(COUNT(*) * SUM(tosc * tosc) - SUM(tosc) * SUM(tosc)) *
	SQRT(COUNT(*) * SUM(todep * todep) - SUM(todep) * SUM(todep))) AS sc_corr,
        
	-- Correlation between depression and acculturative stress
	(COUNT(*) * SUM(toas * todep) - SUM(toas) * SUM(todep)) /
	(SQRT(COUNT(*) * SUM(toas * toas) - SUM(toas) * SUM(toas)) *
	SQRT(COUNT(*) * SUM(todep * todep) - SUM(todep) * SUM(todep))) AS as_corr
FROM students_info_staging
WHERE tosc IS NOT NULL AND todep IS NOT NULL
AND toas IS NOT NULL;

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Correlation between depression and length of stay
SELECT
	(COUNT(*) * SUM(stay * todep) - SUM(stay) * SUM(todep)) /
	(SQRT(COUNT(*) * SUM(stay * stay) - SUM(stay) * SUM(stay)) *
	SQRT(COUNT(*) * SUM(todep * todep) - SUM(todep) * SUM(todep))) AS stay_dep_corr,

-- Correlation between length of stay and social connectedness
	
	(COUNT(*) * SUM(stay * tosc) - SUM(stay) * SUM(tosc)) /
	(SQRT(COUNT(*) * SUM(stay * stay) - SUM(stay) * SUM(stay)) *
	QRT(COUNT(*) * SUM(tosc * tosc) - SUM(tosc) * SUM(tosc))) AS stay_sc_corr,
		
-- Correlation between length of stay and acculturative stress
	
	(COUNT(*) * SUM(stay * todep) - SUM(stay) * SUM(todep)) /
	(SQRT(COUNT(*) * SUM(stay * stay) - SUM(stay) * SUM(stay)) *
	SQRT(COUNT(*) * SUM(toas * toas) - SUM(toas) * SUM(toas))) AS stay_as_corr

FROM students_info_staging
WHERE stay IS NOT NULL 
AND tosc IS NOT NULL
AND todep IS NOT NULL
AND toas IS NOT NULL;


