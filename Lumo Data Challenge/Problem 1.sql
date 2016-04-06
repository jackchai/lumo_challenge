#Question 1

#Comments here are my thoughts
#Looking into the activity_data table, I noticed that a lot of owner has NULL or blank values.
#I am going to assume that there may be some corruption in the owner column
#As a result, for the most accurate DAU and MAU, I am going to check that the owner value is in the owner_metadata table

#For this question also, I am assuming that if they have an activity log, that they are active
#We might be able to look at activity to see if the object is being worn (i.e. some activity value > 0)
#I chose not to for the initial run because we know for sure that if the device has been shut off, disconnected, or out of batteries, that no data would be sent


#Also, I am calculating MAU and DAU seperately and them joining the data. In principle, I could just calculate each independently

SELECT a2.local_date,
a2.DAU,
a1.MAU
FROM
(SELECT date_trunc('month', act_time_local) as local_month,
COUNT(DISTINCT owner) as MAU
FROM activity_data
WHERE owner IN (
SELECT owner
FROM owner_metadata
WHERE owner IS NOT NULL)
AND date_trunc('month', act_time_local) = date '2015-10-01'
GROUP BY date_trunc('month', act_time_local)) as a1
JOIN
(SELECT date_trunc('day', act_time_local) as local_date,
COUNT(DISTINCT owner) as DAU
FROM activity_data
WHERE owner IN (
SELECT owner
FROM owner_metadata
WHERE owner IS NOT NULL)
AND date_trunc('month', act_time_local) = date '2015-10-01'
GROUP BY date_trunc('day', act_time_local)) as a2
ON date_trunc('month', a1.local_month) = date_trunc('month', a2.local_date)
ORDER BY a2.local_date 
