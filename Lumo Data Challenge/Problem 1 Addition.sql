# As we learned later in the Part, we can define a more stringent version of active
# This was steps >= 300 or posture time >= 30
# Let's also expand this by looking at the DAU and MAU of more active people


SELECT a2.local_date,
a2.DAU,
a1.MAU
FROM
(SELECT date_trunc('month', local_date) as local_month,
COUNT(DISTINCT owner) as MAU
FROM 
	(SELECT owner,
	SUM(CASE WHEN act_type = 'C_STEPS' THEN act_value ELSE 0 END) as num_steps,
	SUM(CASE WHEN act_type IN ('SG', 'STG', 'CG') THEN act_value ELSE 0 END)/100.0 * 5.0 as good_posture_time,
	date_trunc('day', act_time_local) as local_date
	FROM activity_data
	WHERE owner IN (
	SELECT owner
	FROM owner_metadata
	WHERE owner IS NOT NULL)
	AND date_trunc('month', act_time_local) = date '2015-10-01'
	GROUP BY owner,
	date_trunc('day', act_time_local))
WHERE num_steps >= 500
OR good_posture_time >= 30
GROUP BY date_trunc('month', local_date)) as a1
JOIN
(SELECT date_trunc('day', local_date) as local_date,
COUNT(DISTINCT owner) as DAU
FROM 
	(SELECT owner,
	SUM(CASE WHEN act_type = 'C_STEPS' THEN act_value ELSE 0 END) as num_steps,
	SUM(CASE WHEN act_type IN ('SG', 'STG', 'CG') THEN act_value ELSE 0 END)/100.0 * 5.0 as good_posture_time,
	date_trunc('day', act_time_local) as local_date
	FROM activity_data
	WHERE owner IN (
	SELECT owner
	FROM owner_metadata
	WHERE owner IS NOT NULL)
	AND date_trunc('month', act_time_local) = date '2015-10-01'
	GROUP BY owner,
	date_trunc('day', act_time_local))
WHERE num_steps >= 500
OR good_posture_time >= 30
GROUP BY date_trunc('day', local_date)) as a2
ON date_trunc('month', a1.local_month) = date_trunc('month', a2.local_date)
ORDER BY a2.local_date 
