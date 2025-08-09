/*

Cleaning and Analysing Data in SQL Queries

*/

SELECT *
FROM students_info;

----------------------------------------------------------------------------------------------------------------------------------------------
-- Staging

CREATE TABLE students_info_staging 
LIKE students_info;

INSERT students_info_staging
SELECT *
FROM students_info;

SELECT *
FROM students_info_staging;
----------------------------------------------------------------------------------------------------------------------------------------------

DESCRIBE students_info_staging;

ALTER TABLE students_info_staging
RENAME COLUMN `ï»¿index` TO `index`; 

/*
NOTE:
- This is a common issue that arises when a CSV file is imported with a Byte Order Mark (BOM). 
- The BOM is a special character at the beginning of a file that indicates the encoding.
- Some database systems, when importing the file, mistakenly include this character as part of the first column's name.
- As a result, the column name becomes something unexpected like ï»¿index instead of just index.

To fix this, you should do one of the following:
1. Find the correct column name: Use a command like DESCRIBE students_info_staging to see the exact names of all columns in the table. 
Then, use that exact name in your ALTER TABLE query.

2. If it doesn't update properly:
-- Re-export the CSV file from its source without the BOM. 
-- You can often do this by saving the file with a different encoding, such as UTF-8 without BOM. 
-- Then, re-import the clean file into your database.

*/

----------------------------------------------------------------------------------------------------------------------------------------------
-- Identify duplicates

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY inter_dom, region, gender, academic, age, stay, stay_cate) AS row_num
FROM students_info_staging;


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

----------------------------------------------------------------------------------------------------------------------------------------------
-- Remove duplicates using a CTE
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY inter_dom, region, gender, academic, age, stay, stay_cate, age, phone_bi) AS row_num
FROM students_info_staging
)

DELETE 
FROM duplicate_cte
WHERE row_num > 1;

----------------------------------------------------------------------------------------------------------------------------------------------
-- Since the target table duplicate_cte of the delete is not updatable, we create another table using a create statement

CREATE TABLE `students_info_staging_2` (
  `index` int DEFAULT NULL,
  `inter_dom` text,
  `region` text,
  `gender` text,
  `academic` text,
  `age` int DEFAULT NULL,
  `age_cate` int DEFAULT NULL,
  `stay` int DEFAULT NULL,
  `stay_cate` text,
  `japanese` int DEFAULT NULL,
  `japanese_cate` text,
  `english` int DEFAULT NULL,
  `english_cate` text,
  `intimate` text,
  `religion` text,
  `suicide` text,
  `dep` text,
  `deptype` text,
  `todep` int DEFAULT NULL,
  `depsev` text,
  `tosc` int DEFAULT NULL,
  `apd` int DEFAULT NULL,
  `ahome` int DEFAULT NULL,
  `aph` int DEFAULT NULL,
  `afear` int DEFAULT NULL,
  `acs` int DEFAULT NULL,
  `aguilt` int DEFAULT NULL,
  `amiscell` int DEFAULT NULL,
  `toas` int DEFAULT NULL,
  `partner` int DEFAULT NULL,
  `friends` int DEFAULT NULL,
  `parents` int DEFAULT NULL,
  `relative` int DEFAULT NULL,
  `profess` int DEFAULT NULL,
  `phone` int DEFAULT NULL,
  `doctor` int DEFAULT NULL,
  `reli` int DEFAULT NULL,
  `alone` int DEFAULT NULL,
  `others` int DEFAULT NULL,
  `internet` text,
  `partner_bi` text,
  `friends_bi` text,
  `parents_bi` text,
  `relative_bi` text,
  `professional_bi` text,
  `phone_bi` text,
  `doctor_bi` text,
  `religion_bi` text,
  `alone_bi` text,
  `others_bi` text,
  `internet_bi` text,
   `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


----------------------------------------------------------------------------------------------------------------------------------------------
-- Update table

INSERT INTO students_info_staging_2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY inter_dom, region, gender, academic, age, stay, stay_cate, age, phone_bi) AS row_num
FROM students_info_staging;

DELETE 
FROM students_info_staging_2
WHERE row_num > 1;

SELECT *
FROM students_info_staging_2
;

----------------------------------------------------------------------------------------------------------------------------------------------
-- Delete Unused Columns

SELECT *
FROM students_info_staging_2;


ALTER TABLE students_info_staging_2
DROP COLUMN row_num;


----------------------------------------------------------------------------------------------------------------------------------------------
-- Standardize data

-- REPLACE function
UPDATE students_info_staging_2
SET inter_dom = 'Domestic'
WHERE inter_dom = 'Dom';

UPDATE students_info_staging_2
SET academic = 'Graduate'
WHERE academic = 'Grad';

----------------------------------------------------------------------------------------------------------------------------------------------
-- TRIM function
SELECT *,
LTRIM(inter_dom)
FROM students_info_staging_2;


SELECT *,
TRIM(stay_cate)
FROM students_info_staging_2;

----------------------------------------------------------------------------------------------------------------------------------------------
-- CASE function
SELECT *,
UPPER(english_cate)
FROM students_info_staging_2;

SELECT *,
INITCAP(gender)
FROM students_info_staging_2;

SELECT 
	CONCAT(UPPER(SUBSTRING(gender, 1, 1)), LOWER(SUBSTRING(gender, 2))) AS gender_standardized
FROM students_info_staging_2;

SELECT 
UPPER(TRIM(gender)) AS standardized_gender
FROM students_info_staging_2;


UPDATE students_info_staging_2
SET gender = UPPER(TRIM(gender));

UPDATE students_info_staging_2
SET gender = CONCAT(UPPER(SUBSTRING(gender, 1, 1)), LOWER(SUBSTRING(gender, 2)));

---------------------------------------------------------------------------------------------------------------------------------------------
-- Dealing with NULL or BLANK values

SELECT COALESCE(intimate, 'Unknown') AS intimate,
	   COALESCE(internet, '0') AS internet
FROM students_info_staging_2;


-- The COALESCE function can be used within the SET clause to achieve the desired result.
UPDATE students_info_staging_2
SET intimate = COALESCE(intimate, 'Unknown'),
    internet = COALESCE(internet, '0');

----------------------------------------------------------------------------------------------------------------------------------------------
/*
- However, the COALESCE function only works on NULL values. 
- It won't affect columns that contain empty strings ('') or strings with only whitespace
- To fix this, check for these empty strings and replace them. 
- Use a CASE statement to check for both NULL and empty strings.
*/

UPDATE students_info_staging_2
SET intimate = CASE
                   WHEN intimate IS NULL OR TRIM(intimate) = '' THEN 'Unknown'
                   ELSE intimate
               END,
    internet = CASE
                   WHEN internet IS NULL OR TRIM(internet) = '' THEN '0'
                   ELSE internet
               END;
               
SELECT *
FROM students_info_staging_2;

----------------------------------------------------------------------------------------------------------------------------------------------
-- Exploratory data analysis
-- Creating bins

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
    students_info_staging_2
WHERE
    age IS NOT NULL
LIMIT 50;   

SELECT *
FROM students_info_staging_2;

-------------------------------------------------------------------------------------------------------------------------------------------
-- Creating a new bin column and updating the calculated values

ALTER TABLE students_info_staging_2
ADD COLUMN age_group VARCHAR(10);

UPDATE students_info_staging_2
SET age_group = CASE
    WHEN CAST(age AS SIGNED) >= 15 AND CAST(age AS SIGNED) <= 19 THEN '15-19'
    WHEN CAST(age AS SIGNED) >= 20 AND CAST(age AS SIGNED) <= 24 THEN '20-24'
    WHEN CAST(age AS SIGNED) >= 25 AND CAST(age AS SIGNED) <= 29 THEN '25-29'
    WHEN CAST(age AS SIGNED) >= 30 AND CAST(age AS SIGNED) <= 34 THEN '30-34'
    WHEN CAST(age AS SIGNED) >= 35 THEN '35+'
    ELSE 'Unknown'
END;

SELECT *
FROM students_info_staging_2;

----------------------------------------------------------------------------------------------------------------------------------------------
-- Descriptive Statistics
-- avg, sum, min, max, count, distinct count

SELECT 
	gender,
	AVG(age) AS avg_age,
	COUNT(age_cate) AS category,
	AVG(tosc) AS avg_social_connectedness ,
	SUM(apd) AS sum_apd,
	MIN(ahome) AS min_ahome,
	MAX(aph) AS max_aph,
	COUNT(DISTINCT region) AS region
FROM students_info_staging_2
	WHERE gender = 'Male' OR gender = 'Female'
	GROUP BY gender;
    

----------------------------------------------------------------------------------------------------------------------------------------------    
-- Frequency Distributions

SELECT DISTINCT (gender), COUNT(age) AS age
FROM students_info_staging_2
GROUP BY gender, age
ORDER BY COUNT(age) DESC;


SELECT
    gender,
    age,
    COUNT(*) AS frequency
FROM
    students_info_staging_2
GROUP BY
    gender, age
ORDER BY
    frequency DESC;
    


SELECT age, gender, parents_bi, parents
FROM students_info_staging_2
	WHERE gender = 'Male' AND parents_bi = 'Yes'
		ORDER BY age DESC;
        
----------------------------------------------------------------------------------------------------------------------------------------------
-- Average scores of depression, social correctness, and acculturative stress levels among international students.

SELECT 
	gender,
	ROUND(AVG(CAST(todep AS SIGNED))) AS avg_depression,
	ROUND(AVG(CAST(tosc AS SIGNED))) AS avg_social_correctedness,
	ROUND(AVG(CAST(todep AS SIGNED))) AS avg_acculturative_stress
FROM students_info_staging_2
	WHERE 
	 todep IS NOT NULL AND
	 tosc IS NOT NULL AND 
	 toas IS NOT NULL  AND
	inter_dom = 'Inter' AND inter_dom IS NOT NULL 
	GROUP BY gender;
    
----------------------------------------------------------------------------------------------------------------------------------------------
-- Correlation Analysis

SELECT
    (SUM(T.X * T.Y) - (SUM(T.X) * SUM(T.Y) / COUNT(*))) /
    SQRT((SUM(T.X*T.X) - POW(SUM(T.X), 2) / COUNT(*)) * (SUM(T.Y*T.Y) - POW(SUM(T.Y), 2) / COUNT(*))) AS inter_dom_correlation
FROM (
    SELECT
        CASE WHEN inter_dom = 'Inter' THEN 1 ELSE 0 END AS X,
        todep AS Y
    FROM students_info_staging_2
    WHERE
        inter_dom IS NOT NULL AND todep IS NOT NULL
) AS T;


----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------