
# Business Question-1: 
WITH Total_trips AS (
SELECT 
  COUNT(trip_id) AS total_trips_all
FROM 
  trips_db.fact_trips
  ) 
SELECT 
    city_name,
    COUNT(*) AS total_trips,
    ROUND((SUM(fare_amount) / SUM(distance_travelled_km)), 2) AS avq_fare_per_km,
    ROUND((AVG(fare_amount)), 2) AS avg_fare_per_trip,
    ROUND((COUNT(trip_id) * 100)/total_trips_all, 2) AS percentage_contribution_to_total_trips
FROM 
    trips_db.fact_trips
JOIN 
    trips_db.dim_city 
    ON 
    dim_city.city_id = fact_trips.city_id
JOIN
    Total_trips
GROUP BY 
    city_name,total_trips_all;

 # Business Request - 2
# RENAMING COLUMNS
ALTER TABLE trips_db.fact_trips     -- Table fact_trips date column 
RENAME COLUMN date TO start_of_month;

ALTER TABLE targets_db.monthly_target_trips      -- Table monthly_target_trips month column
RENAME COLUMN month TO start_of_month;

# UPDATING Table facts_trips column start_of_month  

UPDATE trips_db.fact_trips
SET start_of_month = date_format(start_of_month,'%Y-%m-%01');

SELECT 
   c.city_name,
   Date_format(m.start_of_month,'%M') AS month,
   count(f.trip_id) AS total_trips,
   m.total_target_trips AS target_trips,
CASE
   WHEN count(f.trip_id)>(m.total_target_trips) THEN 'Above Target'
   WHEN count(f.trip_id)<(m.total_target_trips) THEN 'Below Target' END AS performance,
   count(f.trip_id)-(m.total_target_trips)/(m.total_target_trips)*100 AS percentage_diffenence
FROM 
   trips_db.dim_city c 
JOIN 
    trips_db.fact_trips f 
ON 
    c.city_id=f.city_id  
JOIN 
    targets_db.monthly_target_trips m 
ON 
    m.city_id=f.city_id 
AND 
    m.start_of_month=f.start_of_month 
GROUP BY 
    c.city_name,f.start_of_month
ORDER BY 
    city_id,start_of_month;

# Business Request - 3
SELECT 
    c.city_name,
    CONCAT(ROUND(100 * SUM(CASE WHEN rtd.trip_count = '2-Trips' THEN rtd.repeat_passenger_count END) / SUM(rtd.repeat_passenger_count), 2), '%') AS '2-Trips',
    CONCAT(ROUND(100 * SUM(CASE WHEN rtd.trip_count = '3-Trips' THEN rtd.repeat_passenger_count END) / SUM(rtd.repeat_passenger_count), 2), '%') AS '3-Trips',
    CONCAT(ROUND(100 * SUM(CASE WHEN rtd.trip_count = '4-Trips' THEN rtd.repeat_passenger_count END) / SUM(rtd.repeat_passenger_count), 2), '%') AS '4-Trips',
    CONCAT(ROUND(100 * SUM(CASE WHEN rtd.trip_count = '5-Trips' THEN rtd.repeat_passenger_count END) / SUM(rtd.repeat_passenger_count), 2), '%') AS '5-Trips',
    CONCAT(ROUND(100 * SUM(CASE WHEN rtd.trip_count = '6-Trips' THEN rtd.repeat_passenger_count END) / SUM(rtd.repeat_passenger_count), 2), '%') AS '6-Trips',
    CONCAT(ROUND(100 * SUM(CASE WHEN rtd.trip_count = '7-Trips' THEN rtd.repeat_passenger_count END) / SUM(rtd.repeat_passenger_count), 2), '%') AS '7-Trips',
    CONCAT(ROUND(100 * SUM(CASE WHEN rtd.trip_count = '8-Trips' THEN rtd.repeat_passenger_count END) / SUM(rtd.repeat_passenger_count), 2), '%') AS '8-Trips',
    CONCAT(ROUND(100 * SUM(CASE WHEN rtd.trip_count = '9-Trips' THEN rtd.repeat_passenger_count END) / SUM(rtd.repeat_passenger_count), 2), '%') AS '9-Trips',
    SUM(rtd.repeat_passenger_count) AS total_repeat_passengers
FROM 
    trips_db.dim_repeat_trip_distribution rtd
JOIN 
    trips_db.dim_city c ON c.city_id = rtd.city_id
GROUP BY 
    c.city_name;


# Business Request - 4
SELECT 
    city_name,
    SUM(fps.new_passengers) AS total_new_passengers,
    CASE 
        WHEN RANK() OVER (ORDER BY SUM(fps.new_passengers) DESC) <= 3 THEN 'Top 3'
        WHEN RANK() OVER (ORDER BY SUM(fps.new_passengers) ASC) <= 3 THEN 'Bottom 3'
        ELSE ' '
    END AS city_category
FROM 
    trips_db.dim_city c
JOIN 
    trips_db.fact_passenger_summary fps 
    ON c.city_id = fps.city_id
GROUP BY 
    c.city_name
ORDER BY 
    total_new_passengers DESC;


# Business Request - 5
WITH ranked_revenue AS (
SELECT 
 city_name,
 start_of_month ,
 SUM(fare_amount) AS Revenue,
 ROW_NUMBER() OVER (PARTITION BY city_name ORDER BY SUM(fare_amount)DESC) AS rank_number
 FROM
  trips_db.fact_trips
JOIN 
  trips_db.dim_city 
ON
 dim_city.city_id=fact_trips.city_id GROUP BY city_name,start_of_month ORDER BY  city_name)
SELECT city_name,start_of_month,Revenue,ROUND((Revenue/(SELECT sum(Revenue) FROM ranked_revenue WHERE city_name=r.city_name)*100),2) FROM ranked_revenue r WHERE rank_number =1;
 


# Business Request - 6

ALTER TABLE trips_db.fact_passenger_summary      -- Table monthly_target_trips month column
RENAME COLUMN  month TO start_of_month;


SELECT
    c.city_name,
    DATE_FORMAT(p.start_of_month, '%M') AS month,
    p.total_passengers,
    p.repeat_passengers,
    CONCAT(
        ROUND(
            100 * (
                (p.repeat_passengers - LAG(p.repeat_passengers) OVER (PARTITION BY p.city_id ORDER BY p.start_of_month))
                / LAG(p.repeat_passengers) OVER (PARTITION BY p.city_id ORDER BY p.start_of_month)
            ), 2
        ), ' %'
    ) AS RPR_percentage_over_month
FROM
    trips_db.fact_passenger_summary p
JOIN
    trips_db.dim_city c ON c.city_id = p.city_id
ORDER BY
    p.city_id, p.start_of_month;
 
SELECT
    city_name,
    SUM(total_passengers) AS total_passengers,
    SUM(repeat_passengers) AS total_repeat_passengers,
    ROUND(SUM(repeat_passengers) / SUM(total_passengers) * 100, 2) AS RPR_percentage
FROM 
    trips_db.fact_passenger_summary fps
JOIN
    trips_db.dim_city dc ON fps.city_id = dc.city_id
GROUP BY
    city_name
ORDER BY
    city_name;
 
 
SELECT
    c.city_name,
    DATE_FORMAT(p.start_of_month, '%M') AS month,
    p.total_passengers,
    p.repeat_passengers,
    CONCAT(
        ROUND(100 * (p.repeat_passengers / p.total_passengers), 2), ' %'
    ) AS monthly_repeat_passenger_rate
FROM
    trips_db.fact_passenger_summary p
JOIN
    trips_db.dim_city c ON p.city_id = c.city_id
ORDER BY
    p.city_id, p.start_of_month;

 
 #PRIMARY RESEARCH QUESTION 
 -- REPORT_7--
 -- 1.Total_Trips vs Target_Trips--
 SELECT 
   (SELECT city_name FROM trips_db.dim_city c WHERE c.city_id = m.city_id) AS city_name,
   DATE_FORMAT(m.start_of_month, '%M') AS month,
   m.total_target_trips,
   COUNT(t.trip_id) AS target_trips,
   CASE
       WHEN COUNT(t.trip_id) = m.total_target_trips THEN 'Target Met'
       WHEN COUNT(t.trip_id) > m.total_target_trips THEN 'Target Exceeded'
       WHEN COUNT(t.trip_id) < m.total_target_trips THEN 'Target Missed'
   END AS performance,
   round((((COUNT(t.trip_id) - m.total_target_trips) / m.total_target_trips) * 100),2) AS percentage_difference
FROM 
   targets_db.monthly_target_trips m
JOIN 
   trips_db.fact_trips t 
ON 
   t.city_id = m.city_id 
AND 
   t.start_of_month = m.start_of_month
GROUP BY 
   m.city_id, m.start_of_month, m.total_target_trips
ORDER BY 
   m.city_id, m.start_of_month;
   
 -- 2.Total_New_Passengers vs Target_New_Passengers--
ALTER TABLE  targets_db.monthly_target_new_passengers      
RENAME COLUMN month TO start_of_month;
 
 SELECT 
   (SELECT city_name FROM trips_db.dim_city c WHERE c.city_id = m.city_id) AS city_name,
   DATE_FORMAT(m.start_of_month, '%M') AS month,
   m.target_new_passengers,
   f.new_passengers AS total_new_passengers,
   CASE
       WHEN f.new_passengers = m.target_new_passengers THEN 'Target Met'
       WHEN f.new_passengers > m.target_new_passengers THEN 'Target Exceeded'
       WHEN f.new_passengers < m.target_new_passengers THEN 'Target Missed'
   END AS performance,
   round((((f.new_passengers - m.target_new_passengers) / m.target_new_passengers) * 100),2) AS percentage_difference
FROM 
   targets_db.monthly_target_new_passengers m
JOIN 
   trips_db.fact_passenger_summary f 
ON 
   m.city_id = f.city_id 
AND 
   m.start_of_month = f.start_of_month
GROUP BY 
   m.city_id, m.start_of_month, m.target_new_passengers
ORDER BY 
   m.city_id, m.start_of_month;
   
   -- 2.Target_avg_passenger_rating vs Passenger_rating--
   SELECT 
   (SELECT city_name FROM trips_db.dim_city c WHERE c.city_id = t.city_id) AS city_name,
   target_avg_passenger_rating,
   round(avg(f.passenger_rating),2) AS Passenger_rating,
   CASE
       WHEN avg(f.passenger_rating) = target_avg_passenger_rating THEN 'Target Met'
       WHEN avg(f.passenger_rating) > target_avg_passenger_rating THEN 'Target Exceeded'
       WHEN avg(f.passenger_rating) < target_avg_passenger_rating THEN 'Target Missed'
   END AS performance
FROM 
   targets_db.city_target_passenger_rating t
JOIN 
   trips_db.fact_trips f 
ON 
   t.city_id = f.city_id 
GROUP BY 
   f.city_id;





