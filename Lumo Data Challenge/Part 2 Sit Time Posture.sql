#As we are trying to help with posture, it is indeed a hypothesis that the longer one sits, the worse the posture becomes.
#As a result, we can try to measure this by looking at the fraction of time in good posture as the cumulative time of the sit session increases
#From this perspective, we'll need to sessionize the sit data similar to how we sessionized in Problem 4 (bascially consecutive 5 minute intervals in which sitting was more than 75% of the time)
#We will then compare this number to the average percentage of good sit time

SELECT cast(total_cum_sitting_time/10 as int) * 10 as minutes_of_sitting,
AVG(perc_good_sit) as avg_good_sit
FROM
(SELECT owner,
session_id,
good_sit_time*1.0/sitting_time as perc_good_sit,
inactive,
SUM(sitting_time/100 * 5) OVER(PARTITION BY owner ORDER BY session_id rows between unbounded preceding and current row) as total_cum_sitting_time
FROM
(SELECT owner,
act_time_local,
sitting_time,
good_sit_time,
inactive,
SUM(inactive) OVER(PARTITION BY owner ORDER BY act_time_local rows between unbounded preceding and current row) as session_id
FROM
(SELECT overall.owner,
overall.act_time_local,
COALESCE(activity.inactive, overall.inactive) as inactive,
good_sit_time,
sitting_time
FROM
(SELECT owner,
act_time_local,
1 as inactive
FROM
(SELECT DISTINCT owner,
1 as arbitrary
FROM owner_metadata
WHERE owner IS NOT NULL
AND owner != '') as a1
JOIN
(SELECT DISTINCT 
act_time_local,
1 as arbitrary
FROM activity_data
WHERE date_trunc('month', act_time_local) = date '2015-10-01') as a2
ON a1.arbitrary = a2.arbitrary) as overall
LEFT JOIN
(SELECT owner,
act_time_local,
good_sit_time,
sitting_time,
CASE WHEN sitting_time >= 75 THEN 0 ELSE 1 END as inactive
FROM
(SELECT owner,
SUM(CASE WHEN act_type = 'SG' THEN act_value ELSE 0 END) as good_sit_time,
SUM(CASE WHEN act_type IN ('SG', 'SBS', 'SBF') THEN act_value ELSE 0 END) as sitting_time,
act_time_local
FROM activity_data
WHERE date_trunc('month', act_time_local) = date '2015-10-01'
GROUP BY owner,
act_time_local)) as activity
ON overall.owner = activity.owner
AND overall.act_time_local = activity.act_time_local)
ORDER BY owner,
act_time_local)
WHERE inactive = 0)
GROUP BY cast(total_cum_sitting_time/10 as int) * 10
ORDER BY cast(total_cum_sitting_time/10 as int) * 10
