# lumo_challenge

Note in here that for Part 1, every problem is broken into the sql code for the problem itself and a sql code for the addition
The Ipython notebook for visualizations (and accompany html file) is just a visualization for the data requested in part 1 based upon the json's downloaded from the SQL query

Brief description of the Additions to each Problem in Part 1

Overall - There are multiple SQL queries in each .sql file. For Problems 2, 3, 4, the first queries were included to better communicate the different parts I was trying to build to accomplish the task. In all cases, the final SQL query at the bottom is the one used to generate the data (all parts put together)

Problem 1 Addition - Added more stringent conditions for definition of active based upon Problem 4

Problem 2 Addition - Added correlation of good posture (pivoted original question to correlation of bad posture)

Problem 3 Addition - Added a version in which we looked at the first quartile, Median, and 3rd Quartile

Problem 4 Addition - Altered the code so that the streak includes active times before 11/15 that ended or continued into the time window of 11/15 to 12/15




For part 2 - I've done 2 things.

Hour of day activity - I just made a quick visualization for what type of activities people do during the day based upon the highest output of the sensor in that hour.

Sit Time GP - This is a correlation I was finding over the general population of how much good posture is related to how long the user sits for. Basically it involves sessionizing the sit time and seeing if good posture becomes less likely as the user sits for longer.

I've again included the fragments of SQL into .sql files and the visualizations into the Part 2 ipython notebook and corresponding HTML files.

