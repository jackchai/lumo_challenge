#In the initial investigation of the data for this problem I noticed a few things
#There are negative values associated with the act_type C_CVBUZZ (indicating negative vibrations) - seeing as how we cannot possibly have negative vibrations, I am going to assume that these are corrupt values and should not be considered

#Also, we have to account for what happens if the device is not on the person (vibe = 0 and posture_time = 0), or if the device is only being worn part of the 5 minute interval
#Happily, the opposite of good posture is bad posture. So in this case, I will reframe the question to look at the correlation between vibrations and the amount of bad posture

#For the answer below, I will break it into parts and then have a final answer



#Query part 1:
#The query below is just to show how I will do some simple mathematics. Effectively, I am pivoting the table, such that bad_posture_times are in a column as opposed to rows and the num_vibrations are also columns
#I have included an inactive time because I will want to ignore the times in which the device is completely inactive

SELECT 
date_trunc('day', act_time_local) as local_date,
act_time_local as local_time,
owner,
SUM(CASE WHEN act_type = 'C_CVBUZZ' THEN act_value ELSE 0 END) as num_vibrations,
SUM(CASE WHEN act_type IN ('CBS', 'CBF', 'SBS', 'SBF', 'STBF', 'STBS') THEN act_value ELSE 0 END) as bad_posture_time,
SUM(CASE WHEN act_type = 'INACT' THEN act_value ELSE 0 END) as inact_time
FROM activity_data
WHERE owner IN (
SELECT owner
FROM owner_metadata
WHERE owner IS NOT NULL)
AND act_type IN ('C_CVBUZZ', 'CBS', 'CBF', 'SBS', 'SBF', 'STBF', 'STBS', 'INACT')
AND date_trunc('month', act_time_local) = date '2015-12-01'
GROUP BY date_trunc('day', act_time_local),
act_time_local,
owner
LIMIT 1000


#Below are some sql queries that I use to look at what the distribution of variables look like
SELECT COUNT(1) as num_times,
inact_time
FROM
(SELECT 
date_trunc('day', act_time_local) as local_date,
act_time_local as local_time,
owner,
SUM(CASE WHEN act_type = 'C_CVBUZZ' THEN act_value ELSE 0 END) as num_vibrations,
SUM(CASE WHEN act_type IN ('CBS', 'CBF', 'SBS', 'SBF', 'STBF', 'STBS') THEN act_value ELSE 0 END) as bad_posture_time,
SUM(CASE WHEN act_type = 'INACT' THEN act_value ELSE 0 END) as inact_time
FROM activity_data
WHERE owner IN (
SELECT owner
FROM owner_metadata
WHERE owner IS NOT NULL)
AND act_type IN ('C_CVBUZZ', 'CBS', 'CBF', 'SBS', 'SBF', 'STBF', 'STBS', 'INACT')
AND date_trunc('month', act_time_local) = date '2015-12-01'
GROUP BY date_trunc('day', act_time_local),
act_time_local,
owner)
GROUP BY inact_time
ORDER BY inact_time

#There seems to be negative inactive times as well as a decent percentage over 90%. For the purposes of our analysis, I am going to look at only the samples in which inactive time > 0 and < 90 (to avoid the behaviour of not hvaing enough time to vibrate)
#Now if we also look at the distribution of bad_posture_time (see below) we see a few things also
SELECT COUNT(1),
bad_posture_time
FROM
(SELECT 
date_trunc('day', act_time_local) as local_date,
act_time_local as local_time,
owner,
SUM(CASE WHEN act_type = 'C_CVBUZZ' THEN act_value ELSE 0 END) as num_vibrations,
SUM(CASE WHEN act_type IN ('CBS', 'CBF', 'SBS', 'SBF', 'STBF', 'STBS') THEN act_value ELSE 0 END) as bad_posture_time,
SUM(CASE WHEN act_type = 'INACT' THEN act_value ELSE 0 END) as inact_time
FROM activity_data
WHERE owner IN (
SELECT owner
FROM owner_metadata
WHERE owner IS NOT NULL)
AND act_type IN ('C_CVBUZZ', 'CBS', 'CBF', 'SBS', 'SBF', 'STBF', 'STBS', 'INACT')
AND date_trunc('month', act_time_local) = date '2015-12-01'
GROUP BY date_trunc('day', act_time_local),
act_time_local,
owner)
WHERE inact_time >= 0
AND inact_time < 90
AND num_vibrations > 0
GROUP BY bad_posture_time
ORDER BY bad_posture_time







#There are quite a few samples at <= 0 and >= 100. A few things here:
#Any negative and > 100 values are again likely meaningless and therefore should likely be thrown out

#Let's now put this all together


SELECT local_date,
owner,
numerator/(|/(vibe_variance * post_variance)) as correlation
FROM
(SELECT a1.local_date,
a1.owner,
SUM((a2.num_vibrations - a1.avg_vibe)*(a2.bad_posture_time - a1.avg_post)) as numerator,
SUM((a2.num_vibrations - a1.avg_vibe)^2) as vibe_variance,
SUM((a2.bad_posture_time - a1.avg_post)) as post_variance
FROM
(
	SELECT local_date,   				
	owner,
	AVG(num_vibrations) as avg_vibe,
	AVG(bad_posture_time) as avg_post
	FROM
	(
		SELECT 
		date_trunc('day', act_time_local) as local_date,
		act_time_local as local_time,
		owner,
		SUM(CASE WHEN act_type = 'C_CVBUZZ' THEN act_value ELSE 0 END) as num_vibrations,
		SUM(CASE WHEN act_type IN ('CBS', 'CBF', 'SBS', 'SBF', 'STBF', 'STBS') THEN act_value ELSE 0 END) as bad_posture_time,
		SUM(CASE WHEN act_type = 'INACT' THEN act_value ELSE 0 END) as inact_time
		FROM activity_data
		WHERE owner IN (
			SELECT owner
			FROM owner_metadata
			WHERE owner IS NOT NULL)
		AND act_type IN ('C_CVBUZZ', 'CBS', 'CBF', 'SBS', 'SBF', 'STBF', 'STBS', 'INACT')
		AND date_trunc('month', act_time_local) = date '2015-12-01'
		GROUP BY date_trunc('day', act_time_local),
		act_time_local,
		owner)
	WHERE inact_time >= 0
	AND inact_time < 90
	AND num_vibrations > 0
	AND bad_posture_time >= 0
	AND bad_posture_time <= 100
	GROUP BY local_date,
	owner) as a1
JOIN
(
	SELECT local_date,   				
	owner,
	num_vibrations,
	bad_posture_time
	FROM
	(
		SELECT 
		date_trunc('day', act_time_local) as local_date,
		act_time_local as local_time,
		owner,
		SUM(CASE WHEN act_type = 'C_CVBUZZ' THEN act_value ELSE 0 END) as num_vibrations,
		SUM(CASE WHEN act_type IN ('CBS', 'CBF', 'SBS', 'SBF', 'STBF', 'STBS') THEN act_value ELSE 0 END) as bad_posture_time,
		SUM(CASE WHEN act_type = 'INACT' THEN act_value ELSE 0 END) as inact_time
		FROM activity_data
		WHERE owner IN (
			SELECT owner
			FROM owner_metadata
			WHERE owner IS NOT NULL)
		AND act_type IN ('C_CVBUZZ', 'CBS', 'CBF', 'SBS', 'SBF', 'STBF', 'STBS', 'INACT')
		AND date_trunc('month', act_time_local) = date '2015-12-01'
		GROUP BY date_trunc('day', act_time_local),
		act_time_local,
		owner)
	WHERE inact_time >= 0
	AND inact_time < 90
	AND num_vibrations > 0
	AND bad_posture_time >= 0
	AND bad_posture_time <= 100) as a2
ON a1.local_date = a2.local_date
AND a1.owner = a2.owner
GROUP BY a1.local_date,
a1.owner)
WHERE vibe_variance > 0
AND post_variance > 0
ORDER BY local_date,
owner


#To do a quick check of the output, I took a look at the ratio of positive correlations (> 0) versus neutral/negative correlations (<= 0). Assuming that the hypothesis is that more bad posture leads to more vibrations, we should see more of the positive correlations
#Indeed when I do a quick 
#SELECT COUNT(1) as num_times,
#CASE WHEN correlation > 0 THEN 1 ELSE 0 END as postive_or_negative
#....
#GROUP BY CASE WHEN correlation > 0 THEN 1 ELSE 0 END
#I see nearly a 2:1 ration of positive:neutral/negative correlations suggesting to me that at the very least, the output seems correct