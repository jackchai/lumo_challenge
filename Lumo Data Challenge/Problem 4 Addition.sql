#For Problem 4, there exists the possibility that a user was on a streak before entering 11/15. As a result, we want to know the longest streak (including beforehand) 
#that ended or continued into the time range. As a result, I am adding a slight tweak here. We will consider looking at the streaks for all time before 12-15-2015 
#And then report the longest one within the time window (even if it includes prior information)

SELECT owner,
MAX(length_of_session) as longest_streak,
COUNT(DISTINCT CASE WHEN length_of_session >= 2 THEN session_id ELSE NULL END) as n_streaks
FROM
(SELECT owner,
session_id,
COUNT(DISTINCT local_date) as length_of_session,
MAX(local_date) as local_date
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
WHERE act_time_local < date '2015-12-15') as a2
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
WHERE act_time_local < date '2015-12-15'
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
AND local_date >= date '2015-11-15'
GROUP BY owner
