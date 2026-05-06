SELECT
    city,
    avg(distance_km) AS avg_distance,
    count() AS trip_count,
    max(dateDiff('second', start_time, end_time)) AS max_duration_sec
FROM hw.trips
GROUP BY city
ORDER BY city;
