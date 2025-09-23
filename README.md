## STUDENTS' MENTAL HEALTH - DATA CLEANING AND ANALYSIS IN MYSQL - FULL PROJECT

## PROJECT OVERVIEW:

Does going to university in a different country affect your mental health? A Japanese international university surveyed its students in 2018 and found that international students have a higher risk of mental health difficulties than the general population, and that social connectedness (belonging to a social group) and acculturative stress (stress associated with joining a new culture) are predictive of depression. The project aims to explore 286 student records using MySQL to determine if a similar conclusion can be drawn for international students and whether the length of stay is a contributing factor.


## DATA PROCESSING, CLEANING AND MANIPULATION

- Creating a staging table

        CREATE TABLE students_info_staging 
        LIKE students_info;

        INSERT students_info_staging
        SELECT *
        FROM students_info;

        SELECT *
        FROM students_info_staging;

- Data processing and cleaning

        DESCRIBE students_info_staging;

        ALTER TABLE students_info_staging
        RENAME COLUMN `ï»¿index` TO `index`;

  - The index column had a BOM.
  - This is a common issue that arises when a CSV file is imported with a Byte Order Mark (BOM).
  - The BOM is a special character at the beginning of a file that indicates the encoding.
  - Some database systems, when importing the file, mistakenly include this character as part of the first column's name.
  - As a result, the column name becomes something unexpected like ï»¿index instead of just index.


  
- 

  ●	Cleaned and analysed 286 Students' Mental Health data in PostgreSQL.
  ●	Created a Staging Table to help in the Extract, Transform, Load (ETL) process.
  ●	Utilised the INSERT INTO statement to update the staging table.
  ●	Renamed columns using the ALTER TABLE statement and RENAME COLUMN clause.
  ●	Added columns using the ALTER TABLE statement and the ADD COLUMN clause.
  ●	Deleted unused columns using the ALTER TABLE statement and the DROP COLUMN clause.
  ●	Identified and deleted duplicates using the ROW_NUMBER () OVER (PARTITION BY) statements; 56 records had duplicate values.
  ●	Trimmed whitespaces using the TRIM () function.
  ●	To find and replace inconsistent values, the REPLACE function was utilised.
  ●	To ensure all texts are in the same case, functions like UPPER (), LOWER (), or INITCAP () were applied.
  ●	COALESCE and CASE statements were used to manage null values and classify data.
  ●	Created a BIN column and updated the calculated values.


## EXPLORATORY DATA ANALYSIS

  ● Performed descriptive analysis using the AVG, SUM, MIN, MAX, COUNT, and DISTINCT COUNT functions.
  ● Calculated the frequency distributions using a WHERE clause. There are 67 domestic students, 201 international students, 47 undergraduate students, and 21 graduate students.
  ● Calculated summary statistics utilising AVERAGE, MINIMUM, MAXIMUM, MEAN and STANDARD DEVIATION functions. 
  ● On average, students remain enrolled at the university for approximately 2.15 years, with a minimum duration of 1 year and a maximum of 10 years. 
  ● The standard deviation of about 1.33 suggests that there is fairly consistent variability in the length of stay among students.


## INFERENTIAL STATISTICS

## Depression and International/Domestic Status
Coefficient: 0.07138804926
● The coefficient suggests **a very weak positive correlation**.
● Given that the value is close to zero, there is **no significant linear relationship** between a student's status as either international or domestic and their depression score.
● The slight positive value indicates that, on average, international students may have marginally higher depression scores than their domestic counterparts; however, this association is **statistically insignificant**.

## Depression and Gender
Correlation Coefficient: -0.0127866035
● This value signifies **a very weak negative correlation**.
● Since the coefficient is close to zero, there is **no linear relationship** between a student's gender and their depression score.
● The negative sign suggests that, on average, males may have slightly lower depression scores than females. However, this difference is minimal.
  
## Depression and Social Connectedness
Correlation: -0.5464
● A moderately strong negative relationship exists between depression and social connectedness.
● A negative correlation indicates that as one variable increases, the other typically decreases.
● This implies that as students’ social connectedness (tosc) increases, their depression scores (todep) tend to decline.
● These findings align with established psychological theories and research, which frequently associate stronger social support and connections with lower levels of depression.

## Depression and Acculturative Stress
Correlation: 0.3685
● There is a weak moderate positive correlation between depression and acculturative stress.
● A positive correlation indicates that as one variable increases, the other also tends to increase.
● Consequently, as a student's acculturative stress (toas) rises, their depression score (todep) also tends to increase.
● This finding aligns with existing psychological research, which frequently identifies the stress associated with adapting to a new culture as a risk factor for mental health issues such as depression.

## Depression and length of stay
● A **weak positive correlation** exists between depression and length of stay **(r = 0.0631)**, indicating that as a student's duration of stay increases, there is minimal change in their level of depression. 

## Length of stay and Social Connectedness
● There is a  **weak negative relationship** between length of stay and social connectedness **(r = -0.0405)**, suggesting that the duration of stay has little to no effect on social connectedness.


## Length of stay and Acculturative Stress
● There is a **weak positive correlation** between length of stay and acculturative stress **(r = 0.0040)**, implying nearly no linear relationship between 


## CONCLUSION

**In summary, the correlation analysis reveals that neither a student's international/domestic status nor their gender demonstrates a significant linear relationship with their depression score**.

**To gain deeper insights into these relationships, further exploration using more advanced statistical techniques, such as ANOVA or regression, could be beneficial**.
