## ANALYSING STUDENTS' MENTAL HEALTH 

## PROJECT OVERVIEW:

Does going to university in a different country affect your mental health? A Japanese international university surveyed its students in 2018 and found that international students have a higher risk of mental health difficulties than the general population, and that social connectedness (belonging to a social group) and acculturative stress (stress associated with joining a new culture) are predictive of depression. The project aims to explore 286 student records using MySQL to determine if a similar conclusion can be drawn for international students and whether the length of stay is a contributing factor.

## DATA DICTIONARY

The data contains the following columns:

| Field Name    | Description                                      |
| ------------- | ------------------------------------------------ |
| `inter_dom`     | Types of students (international or domestic)   |
| `japanese_cate` | Japanese language proficiency                    |
| `english_cate`  | English language proficiency                     |
| `academic`      | Current academic level (undergraduate or graduate) |
| `age`           | Current age of student                           |
| `stay`          | Current length of stay in years                  |
| `todep`         | Total score of depression (PHQ-9 test)           |
| `tosc`          | Total score of social connectedness (SCS test)   |
| `toas`          | Total score of acculturative stress (ASISS test) |

## DATA PROCESSING, CLEANING AND MANIPULATION

- Creating a staging table:

        CREATE TABLE students_info_staging 
        LIKE mental_health;

        INSERT students_info_staging
        SELECT *
        FROM mental_health;

        SELECT *
        FROM students_info_staging;

 
- Data cleaning
  
Step 1. Identifying row numbers:

        SELECT *,
        ROW_NUMBER() OVER(
        PARTITION BY inter_dom, region, gender, academic, age, stay, stay_cate) AS row_num
        FROM students_info_staging;

Step 2. Identifying duplicate rows using a CTE:
  
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

A row_num column was added to assist in identifying duplicate records.


Step 3. Checking what will be deleted using a SUBQUERY:

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

**Results:** 141 row(s) affected.


Step 4. Removing duplicate records using a WHERE clause:

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
                
**Results:** 127 row(s) returned

- Standardising data
  
--- REPLACE function:
  
        UPDATE students_info_staging
        SET inter_dom = 'Domestic'
        WHERE inter_dom = 'Dom';

**Results:** 31 row(s) affected Rows matched: 31  Changed: 31  Warnings: 0

        UPDATE students_info_staging
        SET academic = 'Graduate'
        WHERE academic = 'Grad';

**Results:** 20 row(s) affected Rows matched: 20  Changed: 20  Warnings: 0

--- TRIM function:
        SELECT *,
        LTRIM(inter_dom)
        FROM students_info_staging;

**Results:** 127 row(s) returned

        SELECT *,
        TRIM(stay_cate)
        FROM students_info_staging;
        
**Results:** 127 row(s) returned

- Addressing NULL or BLANK values

--- Using a COALESCE function:

		SELECT COALESCE(intimate, 'Unknown') AS intimate,
		COALESCE(internet, '0') AS internet
		FROM students_info_staging;

--- Using a COALESCE function within the SET clause:

		UPDATE students_info_staging
		SET intimate = COALESCE(intimate, 'Unknown'),
    	internet = COALESCE(internet, '0');


- However, the COALESCE function only works on NULL values. 
- It won't affect columns that contain empty strings ('') or strings with only whitespace
- To fix this, check for these empty strings and replace them. 
- Use a CASE statement to check for both NULL and empty strings.

--- Using a CASE statement: 

		UPDATE students_info_staging
		SET intimate = CASE
                   WHEN intimate IS NULL OR TRIM(intimate) = '' THEN 'Unknown'
                   ELSE intimate
               END,
    		internet = CASE
                   WHEN internet IS NULL OR TRIM(internet) = '' THEN 'Unknown'
                   ELSE internet
               END;


## EXPLORATORY DATA ANALYSIS

--- Creating age bins:

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
    		age IS NOT NULL
		LIMIT 50;   

--- Creating a new bin column: 

		ALTER TABLE students_info_staging
		ADD COLUMN age_group VARCHAR(10);

--- Updating the column with calculated values

		UPDATE students_info_staging
		SET age_group = CASE
    		WHEN CAST(age AS SIGNED) >= 15 AND CAST(age AS SIGNED) <= 19 THEN '15-19'
    		WHEN CAST(age AS SIGNED) >= 20 AND CAST(age AS SIGNED) <= 24 THEN '20-24'
    		WHEN CAST(age AS SIGNED) >= 25 AND CAST(age AS SIGNED) <= 29 THEN '25-29'
    		WHEN CAST(age AS SIGNED) >= 30 AND CAST(age AS SIGNED) <= 34 THEN '30-34'
    		WHEN CAST(age AS SIGNED) >= 35 THEN '35+'
    	ELSE 'Unknown'
		END;

--- Descriptive Statistics:

		SELECT 
			gender,
			AVG(age) AS avg_age,
			COUNT(age_cate) AS category,
			AVG(tosc) AS avg_social_connectedness ,
			SUM(apd) AS sum_apd,
			MIN(ahome) AS min_ahome,
			MAX(aph) AS max_aph,
			COUNT(DISTINCT region) AS region
		FROM students_info_staging
		WHERE gender = 'Male' OR gender = 'Female'
		GROUP BY gender;

<img width="1110" height="141" alt="image" src="https://github.com/user-attachments/assets/a72b1fc3-5db6-4a63-af3b-93445c674943" />

--- Frequency distributions:

		SELECT gender, age_group, COUNT(age) AS age
		FROM students_info_staging
		GROUP BY gender, age_group, age
		ORDER BY COUNT(age) DESC;
		
<img width="1037" height="452" alt="image" src="https://github.com/user-attachments/assets/b94dab3b-48cf-4e3f-ac39-bfdb67ad643d" />

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


<img width="990" height="735" alt="image" src="https://github.com/user-attachments/assets/7f6f884d-1a0d-49e1-931f-338d5bc453c0" />

**INFERENTIAL STATISTICS**

## Correlation between students' status and depression:

		SELECT
    		(COUNT(*) * SUM((inter_dom = 'International') * todep) - SUM(inter_dom = 'International') * SUM(todep)) /
    		(SQRT(COUNT(*) * SUM(inter_dom = 'International') - SUM(inter_dom = 'International') * SUM(inter_dom = 'International')) *
     		SQRT(COUNT(*) * SUM(todep * todep) - SUM(todep) * SUM(todep))) AS inter_dom_corr,
    
## Correlation between gender and depression:
	 
    		(COUNT(*) * SUM((gender = 'Male') * todep) - SUM(gender = 'Male') * SUM(todep)) /
    		(SQRT(COUNT(*) * SUM(gender = 'Male') - SUM(gender = 'Male') * SUM(gender = 'Male')) *
     		SQRT(COUNT(*) * SUM(todep * todep) - SUM(todep) * SUM(todep))) AS gender_corr
		FROM students_info_staging
		WHERE inter_dom IN ('International', 'Domestic')
		AND gender IN ('Male', 'Female');

<img width="949" height="118" alt="image" src="https://github.com/user-attachments/assets/90612b52-de4a-4dd4-a6c7-e94772315ac1" />

**Results**

Depression and students' (international or domestic) status

	Coefficient: 0.07138804926
	● The coefficient suggests **a very weak positive correlation**.
	● Given that the value is close to zero, there is **no significant linear relationship** between a student's status as either international or domestic and their depression score.
	● The slight positive value indicates that, on average, international students may have marginally higher depression scores than their domestic counterparts.
	● However, this association is **statistically insignificant**.

Depression and gender

	Correlation Coefficient: -0.0127866035
	● This value signifies **a very weak negative correlation**.
	● Since the coefficient is close to zero, there is **no linear relationship** between a student's gender and their depression score.
	● The negative sign suggests that, on average, males may have slightly lower depression scores than females. However, this difference is minimal.


## Correlation between depression and social connectedness
		SELECT
			(COUNT(*) * SUM(tosc * todep) - SUM(tosc) * SUM(todep)) /
			(SQRT(COUNT(*) * SUM(tosc * tosc) - SUM(tosc) * SUM(tosc)) *
			SQRT(COUNT(*) * SUM(todep * todep) - SUM(todep) * SUM(todep))) AS sc_corr,

## Correlation between depression and acculturative stress
	
			(COUNT(*) * SUM(toas * todep) - SUM(toas) * SUM(todep)) /
			(SQRT(COUNT(*) * SUM(toas * toas) - SUM(toas) * SUM(toas)) *
			SQRT(COUNT(*) * SUM(todep * todep) - SUM(todep) * SUM(todep))) AS as_corr
		FROM students_info_staging
		WHERE tosc IS NOT NULL 
		AND todep IS NOT NULL
		AND toas IS NOT NULL;

<img width="951" height="119" alt="image" src="https://github.com/user-attachments/assets/2eb47348-ee98-41d6-aebc-05c07bf3d4aa" />

**Results**:

Depression and social connectedness

	Correlation coefficient: -0.5464
	● A **moderately strong negative** relationship exists between depression and social connectedness.
	● A negative correlation indicates that as one variable increases, the other typically decreases.
	● This implies that as students’ social connectedness (tosc) increases, their depression scores (todep) tend to decline.
	● These findings align with established psychological theories and research, which frequently associate stronger social support and connections with lower levels of depression.

Depression and acculturative stress

	Correlation coefficient: 0.3685
	● There is a weak moderate positive correlation between depression and acculturative stress.
	● A positive correlation indicates that as one variable increases, the other also tends to increase.
	● Consequently, as a student's acculturative stress (toas) rises, their depression score (todep) also tends to increase.
	● This finding aligns with existing psychological research, which frequently identifies the stress associated with adapting to a new culture as a risk factor for mental health issues such as depression.


## Correlation between depression and length of stay

		SELECT
			(COUNT(*) * SUM(stay * todep) - SUM(stay) * SUM(todep)) /
			(SQRT(COUNT(*) * SUM(stay * stay) - SUM(stay) * SUM(stay)) *
			SQRT(COUNT(*) * SUM(todep * todep) - SUM(todep) * SUM(todep))) AS stay_dep_corr,

## Correlation between length of stay and social connectedness
	
			(COUNT(*) * SUM(stay * tosc) - SUM(stay) * SUM(tosc)) /
			(SQRT(COUNT(*) * SUM(stay * stay) - SUM(stay) * SUM(stay)) *
			SQRT(COUNT(*) * SUM(tosc * tosc) - SUM(tosc) * SUM(tosc))) AS stay_sc_corr,
		
## Correlation between length of stay and acculturative stress
	
			(COUNT(*) * SUM(stay * todep) - SUM(stay) * SUM(todep)) /
			(SQRT(COUNT(*) * SUM(stay * stay) - SUM(stay) * SUM(stay)) *
			SQRT(COUNT(*) * SUM(toas * toas) - SUM(toas) * SUM(toas))) AS stay_as_corr
		
		FROM students_info_staging
		WHERE stay IS NOT NULL 
		AND tosc IS NOT NULL
   		AND todep IS NOT NULL
		AND toas IS NOT NULL;
 
<img width="948" height="114" alt="image" src="https://github.com/user-attachments/assets/3aa6e91d-30b2-4bf8-bf76-a52fefda09b5" />

**Results:**

Depression and length of stay
	● A **weak positive correlation** exists between depression and length of stay **(r = 0.0631)**, indicating that as a student's duration of stay increases, there is minimal change in their level of depression. 

Length of stay and social connectedness
	● There is a  **weak negative relationship** between length of stay and social connectedness **(r = -0.0405)**, suggesting that the duration of stay has little to no effect on social connectedness.


Length of stay and acculturative Stress
	● There is a **weak positive correlation** between length of stay and acculturative stress **(r = 0.0040)**, implying nearly no linear relationship between 


## CONCLUSION

**In summary, the correlation analysis reveals that neither a student's international/domestic status nor their gender demonstrates a significant linear relationship with their depression score**.

**To gain deeper insights into these relationships, further exploration using more advanced statistical techniques, such as ANOVA or regression, could be beneficial**.
