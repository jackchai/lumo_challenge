#In the actual problem 2, I looked at the correlation between bad posture vs vibrations. I wanted to revisit the actual question itself just for a check and an exercise.
#Given the multiple data issues listed as well as the inactivve time, I am going to make some simplifying assumptions
#1. I will only look at data sets in which the inactive_time < 90 percent (to ensure that people are wearing the devices)


SELECT local_date,
owner,
numerator/(|/(vibe_variance * post_variance)) as correlation
FROM
(SELECT a1.local_date,
a1.owner,
SUM((a2.num_vibrations - a1.avg_vibe)*(a2.good_posture_time - a1.avg_post)) as numerator,
SUM((a2.num_vibrations - a1.avg_vibe)^2) as vibe_variance,
SUM((a2.good_posture_time - a1.avg_post)) as post_variance
FROM
(
	SELECT local_date,   				
	owner,
	AVG(num_vibrations) as avg_vibe,
	AVG(good_posture_time) as avg_post
	FROM
	(
		SELECT 
		date_trunc('day', act_time_local) as local_date,
		act_time_local as local_time,
		owner,
		SUM(CASE WHEN act_type = 'C_CVBUZZ' THEN act_value ELSE 0 END) as num_vibrations,
		SUM(CASE WHEN act_type IN ('CG', 'SG', 'STG') THEN act_value ELSE 0 END) as good_posture_time,
		SUM(CASE WHEN act_type = 'INACT' THEN act_value ELSE 0 END) as inact_time
		FROM activity_data
		WHERE owner IN (
			SELECT owner
			FROM owner_metadata
			WHERE owner IS NOT NULL)
		AND act_type IN ('C_CVBUZZ', 'CG', 'SG', 'STG', 'INACT')
		AND date_trunc('month', act_time_local) = date '2015-12-01'
		GROUP BY date_trunc('day', act_time_local),
		act_time_local,
		owner)
	WHERE inact_time >= 0
	AND inact_time < 90
	AND num_vibrations > 0
	AND good_posture_time >= 0
	AND good_posture_time <= 100
	GROUP BY local_date,
	owner) as a1
JOIN
(
	SELECT local_date,   				
	owner,
	num_vibrations,
	good_posture_time
	FROM
	(
		SELECT 
		date_trunc('day', act_time_local) as local_date,
		act_time_local as local_time,
		owner,
		SUM(CASE WHEN act_type = 'C_CVBUZZ' THEN act_value ELSE 0 END) as num_vibrations,
		SUM(CASE WHEN act_type IN ('CG', 'SG', 'STG') THEN act_value ELSE 0 END) as good_posture_time,
		SUM(CASE WHEN act_type = 'INACT' THEN act_value ELSE 0 END) as inact_time
		FROM activity_data
		WHERE owner IN (
			SELECT owner
			FROM owner_metadata
			WHERE owner IS NOT NULL)
		AND act_type IN ('C_CVBUZZ', 'CG', 'SG', 'STG', 'INACT')
		AND date_trunc('month', act_time_local) = date '2015-12-01'
		GROUP BY date_trunc('day', act_time_local),
		act_time_local,
		owner)
	WHERE inact_time >= 0
	AND inact_time < 90
	AND num_vibrations > 0
	AND good_posture_time >= 0
	AND good_posture_time <= 100) as a2
ON a1.local_date = a2.local_date
AND a1.owner = a2.owner
GROUP BY a1.local_date,
a1.owner)
WHERE vibe_variance > 0
AND post_variance > 0
ORDER BY local_date,
owner

#Doing a quick check here also, I will look at the counts of and in this case we also have a nearly 2:1 ratio of negative to non-negative correlation. Again, this indicates to me that the answer makes a bit of sense