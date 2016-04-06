#First we should write something to define activity on a daily basis
SELECT owner,
SUM(CASE WHEN act_type = 'C_STEPS' THEN act_value ELSE 0 END) as num_steps,
SUM(CASE WHEN act_type IN ('SG', 'STG', 'CG') THEN act_value ELSE 0 END)/100.0 * 5.0 as good_posture_time,
date_trunc('day', act_time_local) as local_date
FROM activity_data
WHERE act_time_local >= date '2015-11-15'
AND act_time_local < date '2015-12-15'
GROUP BY owner,
date_trunc('day', act_time_local)

#Now let's define whether users are being active


SELECT owner,
local_date,
CASE WHEN num_steps >= 500 OR good_posture_time >= 30 THEN 0 ELSE 1 END as inactive
FROM
(SELECT owner,
SUM(CASE WHEN act_type = 'C_STEPS' THEN act_value ELSE 0 END) as num_steps,
SUM(CASE WHEN act_type IN ('SG', 'STG', 'CG') THEN act_value ELSE 0 END)/100.0 * 5.0 as good_posture_time,
date_trunc('day', act_time_local) as local_date
FROM activity_data
WHERE act_time_local >= date '2015-11-15'
AND act_time_local < date '2015-12-15'
GROUP BY owner,
date_trunc('day', act_time_local))


#Before we put everything together, we need to have a comprehensive list of owner/dates.
#The reason behind this is that I will have to give a value if a user does not report in on a current day, to do this, I do the following

SELECT owner,
local_date,
1 as inactive
FROM
(SELECT DISTINCT owner,
1 as arbitrary
FROM owner_metadata
WHERE owner IS NOT NULL
AND owner != '') as a1
JOIN
(SELECT DISTINCT 
date_trunc('day', act_time_local) as local_date,
1 as arbitrary
FROM activity_data
WHERE act_time_local >= date '2015-11-15'
AND act_time_local < date '2015-12-15') as a2
ON a1.arbitrary = a2.arbitrary


#Next, on the days that users are active, I want to adjust the value of inactive from 1 to 0

SELECT overall.owner,
overall.local_date,
COALESCE(activity.inactive, overall.inactive) as inactive
FROM
(SELECT owner,
local_date,
1 as inactive
FROM
(SELECT DISTINCT owner,
1 as arbitrary
FROM owner_metadata
WHERE owner IS NOT NULL
AND owner != '') as a1
JOIN
(SELECT DISTINCT 
date_trunc('day', act_time_local) as local_date,
1 as arbitrary
FROM activity_data
WHERE act_time_local >= date '2015-11-15'
AND act_time_local < date '2015-12-15') as a2
ON a1.arbitrary = a2.arbitrary) as overall
LEFT JOIN
(SELECT owner,
local_date,
CASE WHEN num_steps >= 500 OR good_posture_time >= 30 THEN 0 ELSE 1 END as inactive
FROM
(SELECT owner,
SUM(CASE WHEN act_type = 'C_STEPS' THEN act_value ELSE 0 END) as num_steps,
SUM(CASE WHEN act_type IN ('SG', 'STG', 'CG') THEN act_value ELSE 0 END)/100.0 * 5.0 as good_posture_time,
date_trunc('day', act_time_local) as local_date
FROM activity_data
WHERE act_time_local >= date '2015-11-15'
AND act_time_local < date '2015-12-15'
GROUP BY owner,
date_trunc('day', act_time_local))) as activity
ON overall.owner = activity.owner
AND overall.local_date = activity.local_date

#Next we will be creating sessions. Since I've assigned 0's for inactive when a user is active and 1 for when they are inactive
#If I cumulative sum partition by user using a window function order by time

SELECT owner,
local_date,
inactive,
SUM(inactive) OVER(PARTITION BY owner ORDER BY local_date rows between unbounded preceding and current row) as session_id
FROM
(SELECT overall.owner,
overall.local_date,
COALESCE(activity.inactive, overall.inactive) as inactive
FROM
(SELECT owner,
local_date,
1 as inactive
FROM
(SELECT DISTINCT owner,
1 as arbitrary
FROM owner_metadata
WHERE owner IS NOT NULL
AND owner != '') as a1
JOIN
(SELECT DISTINCT 
date_trunc('day', act_time_local) as local_date,
1 as arbitrary
FROM activity_data
WHERE act_time_local >= date '2015-11-15'
AND act_time_local < date '2015-12-15') as a2
ON a1.arbitrary = a2.arbitrary) as overall
LEFT JOIN
(SELECT owner,
local_date,
CASE WHEN num_steps >= 500 OR good_posture_time >= 30 THEN 0 ELSE 1 END as inactive
FROM
(SELECT owner,
SUM(CASE WHEN act_type = 'C_STEPS' THEN act_value ELSE 0 END) as num_steps,
SUM(CASE WHEN act_type IN ('SG', 'STG', 'CG') THEN act_value ELSE 0 END)/100.0 * 5.0 as good_posture_time,
date_trunc('day', act_time_local) as local_date
FROM activity_data
WHERE act_time_local >= date '2015-11-15'
AND act_time_local < date '2015-12-15'
GROUP BY owner,
date_trunc('day', act_time_local))) as activity
ON overall.owner = activity.owner
AND overall.local_date = activity.local_date)
ORDER BY owner,
local_date

#Finally, we can put this all together. We want the session length (Count unique dates) for when a user is active in that current session (inactive = 0)
#Once we do this, to get the max length, we only have to have the max of this value per user
#For the number of distinct sessions, we only have to count the number of times a length gets to 2 (because we are only considering 2 or above)


SELECT owner,
MAX(length_of_session) as longest_streak,
COUNT(DISTINCT CASE WHEN length_of_session >= 2 THEN session_id ELSE NULL END) as n_streaks
FROM
(SELECT owner,
session_id,
COUNT(DISTINCT local_date) as length_of_session
FROM
(SELECT owner,
local_date,
inactive,
SUM(inactive) OVER(PARTITION BY owner ORDER BY local_date rows between unbounded preceding and current row) as session_id
FROM
(SELECT overall.owner,
overall.local_date,
COALESCE(activity.inactive, overall.inactive) as inactive
FROM
(SELECT owner,
local_date,
1 as inactive
FROM
(SELECT DISTINCT owner,
1 as arbitrary
FROM owner_metadata
WHERE owner IS NOT NULL
AND owner != '') as a1
JOIN
(SELECT DISTINCT 
date_trunc('day', act_time_local) as local_date,
1 as arbitrary
FROM activity_data
WHERE act_time_local >= date '2015-11-15'
AND act_time_local < date '2015-12-15') as a2
ON a1.arbitrary = a2.arbitrary) as overall
LEFT JOIN
(SELECT owner,
local_date,
CASE WHEN num_steps >= 500 OR good_posture_time >= 30 THEN 0 ELSE 1 END as inactive
FROM
(SELECT owner,
SUM(CASE WHEN act_type = 'C_STEPS' THEN act_value ELSE 0 END) as num_steps,
SUM(CASE WHEN act_type IN ('SG', 'STG', 'CG') THEN act_value ELSE 0 END)/100.0 * 5.0 as good_posture_time,
date_trunc('day', act_time_local) as local_date
FROM activity_data
WHERE act_time_local >= date '2015-11-15'
AND act_time_local < date '2015-12-15'
GROUP BY owner,
date_trunc('day', act_time_local))) as activity
ON overall.owner = activity.owner
AND overall.local_date = activity.local_date)
ORDER BY owner,
local_date)
WHERE inactive = 0
GROUP BY owner,
session_id)
WHERE length_of_session >= 2
GROUP BY owner



