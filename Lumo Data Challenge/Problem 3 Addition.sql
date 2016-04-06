#For problem 3, in my experience we have often tried to look at distributions (in addition to 95% confidence interval on the mean)
#I am presenting here a version of that distribution by looking at the first, second, and 3rd quartile numbers
#I am also just presenting that here to give a different interpretation of how to understand the differences between male and female


SELECT DISTINCT a2.gender,
a1.local_date,
percentile_cont(0.25) within group (order by a1.numerator*1.0/a1.denominator) over(partition by a2.gender, a1.local_date) as first_quartile,
percentile_cont(0.5) within group (order by a1.numerator*1.0/a1.denominator) over(partition by a2.gender, a1.local_date) as median_value,
percentile_cont(0.75) within group (order by a1.numerator*1.0/a1.denominator) over(partition by a2.gender, a1.local_date) as third_quartile
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
ORDER BY a1.local_date,
a2.gender