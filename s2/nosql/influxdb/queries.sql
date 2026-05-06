SELECT *
FROM temperature
WHERE time >= now() - INTERVAL '5 minutes'
ORDER BY time;

SELECT
    location,
    AVG(value) AS avg_value
FROM temperature
WHERE time >= now() - INTERVAL '5 minutes'
GROUP BY location
ORDER BY location;
