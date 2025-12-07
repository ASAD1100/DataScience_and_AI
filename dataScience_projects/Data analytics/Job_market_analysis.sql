-- SELECT THE DATABASE
USE JOB ;

-- ## DQL STATEMENTS ## --

-- 1. How many records does this table contain?
SELECT COUNT(*) AS records_count 
FROM JOBS_DATA ;

-- 2. Does the data has duplicates ?
SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT job_id) AS unique_jobs
FROM JOBS_DATA ;

-- 3. List the top 5 companies and the number of exact job postings.
SELECT company_name, count(*)
FROM JOBS_DATA 
GROUP BY company_name, [description] 
HAVING COUNT(*) > 1;

-- 4. LIST FIRST 6 FIELDS (COLUMNS) AND DESCRIPTION TOKENS FOR FIVE RANDOM ROWS
SELECT TOP 5
    [index],
    title,
    company_name,
    [location],
    via,
    [description],
    description_tokens
FROM JOBS_DATA 
ORDER BY NEWID();

/* 5. Average Standardized Salary by Schedule Type and Remote Status
What is the average salary_standardized for jobs, broken down by schedule_type and whether they are work_from_home or not?
Include only Full-time and Contract jobs for this analysis. */

SELECT schedule_type,
        CASE 
            WHEN work_from_home = 1 THEN 'Remote'
            ELSE 'On-Site'
        END AS work_location_type,
        ROUND(AVG(salary_standardized),0) Average_Standardized_Salary
FROM JOBS_DATA 
WHERE schedule_type IN ('Full-time', 'Contract')
GROUP BY schedule_type, work_from_home
ORDER BY 3 DESC;

/* 6. Top Job Posting Sources by Total Standardized Salary Offered
Which three job posting sources (via) collectively represent the highest sum 
of standardized salaries (salary_standardized)?*/

SELECT TOP 1 VIA, 
       SUM(salary_standardized) Total_Standardized_Salary
FROM JOBS_DATA 
GROUP BY VIA
ORDER BY 2 DESC ;

/* 7. Job Titles with the Highest Proportion of Remote Opportunities
List the top 5 job titles that have the highest proportion of 
work_from_home positions among all their postings. Consider only titles with at least 3 total postings.*/

SELECT TOP 5
    TITLE,
    CAST(SUM(CASE WHEN work_from_home = 1 THEN 1 ELSE 0 END) / COUNT(*) AS FLOAT)
FROM JOBS_DATA 
GROUP BY TITLE
HAVING COUNT(*) > 3
ORDER BY 2 DESC ;

/* 8. Overall Average Standardized Salary for Hourly vs. Yearly Rates
Compare the overall average standardized salary (salary_standardized) 
for jobs listed as 'hourly' (salary_rate = 'hour') versus 'yearly' (salary_rate = 'year'). */

SELECT salary_rate, 
    ROUND(AVG(salary_standardized), 0) Avg_Standardised_Salary
FROM JOBS_DATA 
GROUP BY salary_rate 
ORDER BY 2 DESC;

SELECT distinct salary_rate FROM JOBS_DATA ;

/* 9. Locations with a High Concentration of Specific Tech Jobs
Identify locations (excluding 'Remote') that containins "developer" AND ("frontend" or "backend")
in their description_tokens. Count how many such jobs each identified location has.*/

SELECT [location], count(*) Count_of_CloudEgineers
FROM JOBS_DATA 
WHERE work_from_home <> 1
AND description_tokens LIKE '%developer%'
AND (description_tokens LIKE '%frontend%' or description_tokens LIKE '%backend%')
GROUP BY [location] ;

/* Salary Comparison for Recently Posted Jobs
Compare the average salary_standardized for jobs posted in the last 7 days (relative to the 
date_time column, assuming date_time represents "now" for the data point) versus jobs posted earlier. */

SELECT CASE 
        WHEN posted_at >= DATEADD(DAY, -7, GETDATE()) THEN 'POSTED LAST 7 DAYS'
        ELSE 'POSTED EARLIER' 
        END AS Posting_Period,
        ROUND(AVG(salary_standardized), 0) Average_Salary
FROM JOBS_DATA 
GROUP BY 
CASE 
        WHEN posted_at >= DATEADD(DAY, -7, GETDATE()) THEN 'POSTED LAST 7 DAYS'
        ELSE 'POSTED EARLIER' 
END
ORDER BY 2 DESC ;


/*10. Determine Days Since Job Posting
Show the title, company_name, posted_at, date_time (the timestamp of when the record was observed), 
and a new calculated column DaysSincePosting which represents how many days have passed between 
the posted_at date and the date_time of the record.*/

SELECT title,
       company_name,
       posted_at,
       DATEDIFF(DAY, posted_at, GETDATE()) as DaysSincePosting
FROM JOBS_DATA 
ORDER BY 4 DESC;

/* 11. Categorize Salary Ranges

Create a new column SalaryTier that categorizes jobs based on their salary_standardized:
'High' if salary_standardized is greater than 120,000
'Medium' if salary_standardized is between 75,000 and 120,000 (inclusive)
'Low' if salary_standardized is less than 75,000
'Unspecified' if salary_standardized is NULL. */

SELECT title,
       company_name,
       salary_standardized,
       CASE 
            WHEN salary_standardized > 120000 THEN 'High'
            WHEN salary_standardized BETWEEN 75000 AND 120000 THEN 'Medium'
            WHEN salary_standardized < 75000 THEN 'Low'
            ELSE 'Unspecified'
       END AS SalaryTier
FROM JOBS_DATA 
ORDER BY 3 DESC;

/* 12. Identify Potential Data/AI/ML Roles

For each job, display its title, company_name, and a boolean-like calculated column IsDataAIMLRole 
that is 1 if "data", "ai", or "machine learning" (or "ml") is present in description_tokens 
(case-insensitive), otherwise 0. */

SELECT title,
       company_name,
       description_tokens,
       CASE 
            WHEN LOWER(description_tokens) LIKE '%data%'
                OR LOWER(description_tokens) LIKE '%ai%'
                OR LOWER(description_tokens) LIKE '%machine learning%'
                OR LOWER(description_tokens) LIKE '%ml%'
            THEN 1
            ELSE 0
       END AS IsDataAIMLRole
FROM JOBS_DATA ;

/* 13. Filter all the data where the IsDataAIMLRole is 1

From the results of above query extract title, company_name and description token of the companies that
has "data", "ai", or "machine learning" (or "ml") is present in description_tokens  */

WITH DsJobs_Data AS (
SELECT title,
       company_name,
       description_tokens,
       CASE 
            WHEN LOWER(description_tokens) LIKE '%data%'
                OR LOWER(description_tokens) LIKE '%ai%'
                OR LOWER(description_tokens) LIKE '%machine learning%'
                OR LOWER(description_tokens) LIKE '%ml%'
            THEN 1
            ELSE 0
       END AS IsDataAIMLRole
FROM JOBS_DATA )
SELECT title, company_name, description_tokens
FROM DsJobs_Data 
WHERE IsDataAIMLRole = 1;

/* 14.standardized Commute Category and Estimated Commute Time in Hours

Create two calculated columns: 
  1.commuteCategory: 'Short' (<= 20 mins), 'Medium' (>20 and <= 45 mins), 
    'Long' (>45 mins), or 'N/A' if commute_time is not numeric.
  2.CommuteTimeInHours: Converts the commute_time (assuming it's in 'X mins' format) to hours. */

SELECT title,
       company_name,
       commute_time,
       CASE
            WHEN TRY_CAST(REPLACE(commute_time, 'mins', '') AS INT) IS NULL THEN 'N/A'
            WHEN TRY_CAST(REPLACE(commute_time, 'mins', '') AS INT) <= 20 THEN 'Short'
            WHEN TRY_CAST(REPLACE(commute_time, 'mins', '') AS INT) BETWEEN 21 AND 45 THEN 'Medium'
            WHEN TRY_CAST(REPLACE(commute_time, 'mins', '') AS INT) > 45 THEN 'Long'
            ELSE 'N/A'
       END AS CommuteCategory,
       CASE 
            WHEN TRY_CAST(REPLACE(commute_time, 'mins', '') AS INT) IS NOT NULL
            THEN ROUND(TRY_CAST(REPLACE(commute_time, 'mins', '') AS FLOAT) / 60, 3)
            ELSE NULL
       END AS CommuteTimeInHours 
FROM JOBS_DATA ;

-- ## alternatively ## --
WITH Commute_Data as 
(SELECT title,
       company_name,
       commute_time,
       TRY_CAST(REPLACE(commute_time, 'mins', '') AS INT) commute_time_mins
FROM JOBS_DATA)
SELECT title,
       company_name,
       commute_time,
       CASE
            WHEN commute_time_mins IS NULL THEN 'N/A'
            WHEN commute_time_mins <= 20 THEN 'Short'
            WHEN commute_time_mins BETWEEN 21 AND 45 THEN 'Medium'
            WHEN commute_time_mins > 45 THEN 'Long'
            ELSE 'N/A'
       END AS CommuteCategory,
       CASE 
            WHEN commute_time_mins IS NOT NULL
            THEN ROUND(TRY_CAST(commute_time_mins AS FLOAT) / 60, 3)
            ELSE NULL
       END AS CommuteTimeInHours
FROM Commute_Data
ORDER BY 5 DESC; 

/* 15. Analyze Average Salary and Remote Job Proportion for Top 5 Job Titles

For the 5 most frequently posted titles (excluding 'Remote' locations), 
calculate their average salary_standardized. Then, for each of these top 5 titles, 
determine the percentage of jobs that are work_from_home. 
Rank these top titles by their average standardized salary. */

WITH TopJobTitle AS (
    SELECT top 5 title
    FROM JOBS_DATA 
    WHERE [location] <> 'Remote'
    GROUP BY title
    order by count(title) desc)
SELECT j.title,
       AVG(j.salary_standardized) as AverageStandardSalary,
       CAST(SUM(CASE WHEN j.work_from_home = 1 THEN 1 ELSE 0 END) AS FLOAT) * 100 / COUNT(j.job_id) RemoteJobPercentage,
       RANK() OVER(ORDER BY AVG(j.salary_standardized) DESC) AS SalaryRank
FROM TopJobTitle tjt
INNER JOIN JOBS_DATA j
ON tjt.TITLE = j.TITLE
GROUP BY j.title;