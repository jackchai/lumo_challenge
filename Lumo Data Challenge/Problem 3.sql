#First and foremost, I wanted to look at the gender distribution
SELECT COUNT(DISTINCT owner) as num_owners,
gender
FROM owner_metadata
GROUP BY gender
#What is extremely interesting about this distribution, is that while most owners are reporting only m or f,
#There are quite a few that have other values ('male', 'F','FEMALE','M', 'MALE','female')
#To grab the entire database, we're going to have to consolidate these values (ignoring the 25 blank values in which we may not be able to infer gender)
#For the consolidation, I will use something like the following
SELECT COUNT(DISTINCT owner) as num_owners,
CASE WHEN lower(gender) LIKE 'm%' THEN 'm' WHEN lower(gender) LIKE 'f%' THEN 'f' ELSE NULL END as gender
FROM owner_metadata
GROUP BY CASE WHEN lower(gender) LIKE 'm%' THEN 'm' WHEN lower(gender) LIKE 'f%' THEN 'f' ELSE NULL END



#I am going to do a bit more for this prompt
#For this analysis too, I will also ignore numerator and denominator values that are outside of the 0 to 100 range (because these will likely be meaningless values)
#Consequently, I will handle it like the following way, the numerator will have to be >= 0 and the denominator > 0 (to allow for division) and both <= 28800 (100 * 24 * 60/5 - the number of five minute intervals in a day)

SELECT owner,
numerator,
denominator
FROM
(SELECT owner,
SUM(CASE WHEN act_type IN ('SG', 'STG', 'CG') THEN act_value ELSE 0 END) as numerator,
SUM(CASE WHEN act_type IN ('R', 'W', 'CG', 'CBS', 'CBF', 'STBS', 'STBF', 'STG', 'SBS', 'SBF', 'S', 'SG') THEN act_value ELSE 0 END) as denominator,
date_trunc('day', act_time_local) as local_date
FROM activity_data
WHERE date_trunc('month', act_time_local) = date '2015-10-01'
GROUP BY owner,
date_trunc('day', act_time_local))
WHERE numerator >= 0
AND numerator <= 28800
AND denominator >= 0
AND denominator <= 28800
AND numerator <= denominator

#If we wanted to look at the 95% confidence interval, then we can calculate a confidence interval on the mean
#And we will want to join on the gender
#For this we can also just do some simple math (note that there is expansion in appendix because the distribution does not seem to be normal)
#95% confidence interval can be +/- 1.96 of the standard error

SELECT gender,
local_date,
avg_posture - 1.96*posture_dev/sqrt(num_values) as lower_posture_bound,
avg_posture,
avg_posture + 1.96*posture_dev/sqrt(num_values) as upper_posture_bound
FROM
(SELECT a2.gender,
a1.local_date,
AVG(a1.numerator*1.0/a1.denominator) as avg_posture,
STDDEV(a1.numerator*1.0/a1.denominator) as posture_dev,
COUNT(1) as num_values
FROM
(SELECT owner,
numerator,
denominator,
local_date
FROM
(SELECT owner,
SUM(CASE WHEN act_type IN ('SG', 'STG', 'CG') THEN act_value ELSE 0 END) as numerator,
SUM(CASE WHEN act_type IN ('R', 'W', 'CG', 'CBS', 'CBF', 'STBS', 'STBF', 'STG', 'SBS', 'SBF', 'S', 'SG') THEN act_value ELSE 0 END) as denominator,
date_trunc('day', act_time_local) as local_date
FROM activity_data
WHERE date_trunc('month', act_time_local) = date '2015-10-01'
GROUP BY owner,
date_trunc('day', act_time_local))
WHERE numerator >= 0
AND numerator <= 28800
AND denominator > 0
AND denominator <= 28800
AND numerator <= denominator) as a1
JOIN 
(SELECT DISTINCT owner,
CASE WHEN lower(gender) LIKE 'm%' THEN 'm' WHEN lower(gender) LIKE 'f%' THEN 'f' ELSE NULL END as gender
FROM owner_metadata
WHERE gender IS NOT NULL
AND gender != ''
AND owner IS NOT NULL
AND owner != '') as a2
ON a1.owner = a2.owner
GROUP BY a2.gender,
a1.local_date)
ORDER BY local_date,
gender
