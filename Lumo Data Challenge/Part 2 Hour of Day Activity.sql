#From the data, I wanted to take a quick look at the hour of day in which people are doing various activities (in the car, sitting, standing, or moving)
#Basically for each hour, I look at what the highest percentage activity is

SELECT AVG(num_owners) as avg_num_owners,
aggregated_activity_type,
cast(local_hour/3600 as int)%24 as hour_of_day
FROM
(SELECT COUNT(DISTINCT owner) as num_owners,
aggregated_activity_type,
local_hour
FROM
(SELECT owner,
local_hour,
aggregated_activity_type,
ROW_NUMBER() OVER(PARTITION BY owner, local_hour ORDER BY percentage_used DESC) as rank_of_activity
FROM
(SELECT owner,
EXTRACT(EPOCH FROM date_trunc('hour', act_time_local)) as local_hour,
CASE WHEN act_type IN ('CG', 'CBS', 'CBF') THEN 'car'
WHEN act_type IN ('SBS', 'SBF', 'SG') THEN 'sit' 
WHEN act_type IN ('STBS', 'STBF','STG') THEN 'stand'
WHEN act_type IN ('W', 'R') THEN 'move'
WHEN act_type IN ('INACT') THEN 'inactive' END as aggregated_activity_type,
SUM(act_value) as percentage_used
FROM activity_data
WHERE owner IN (
SELECT owner
FROM owner_metadata
WHERE owner IS NOT NULL
AND owner != '')
AND date_trunc('month', act_time_local) = date '2015-10-01'
GROUP BY owner,
EXTRACT(EPOCH FROM date_trunc('hour', act_time_local)),
CASE WHEN act_type IN ('CG', 'CBS', 'CBF') THEN 'car'
WHEN act_type IN ('SBS', 'SBF', 'SG') THEN 'sit' 
WHEN act_type IN ('STBS', 'STBF','STG') THEN 'stand'
WHEN act_type IN ('W', 'R') THEN 'move'
WHEN act_type IN ('INACT') THEN 'inactive' END))
WHERE rank_of_activity = 1
GROUP BY local_hour,
aggregated_activity_type)
GROUP BY 
aggregated_activity_type,
cast(local_hour/3600 as int)%24
ORDER BY 
aggregated_activity_type,
cast(local_hour/3600 as int)%24