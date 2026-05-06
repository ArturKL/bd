CREATE DATABASE IF NOT EXISTS hw;

DROP TABLE IF EXISTS hw.trips;

CREATE TABLE hw.trips
(
    trip_id UInt32,
    start_time DateTime,
    end_time DateTime,
    distance_km Float32,
    city String
)
ENGINE = MergeTree()
ORDER BY (city, trip_id);

-- 1 миллион строк: trip_id — UInt32 в диапазоне 1..1_000_000
INSERT INTO hw.trips
SELECT
    toUInt32(number + 1) AS trip_id,
    st AS start_time,
    st + toIntervalSecond(dur_sec) AS end_time,
    dist_km AS distance_km,
    city_name AS city
FROM
(
    SELECT
        number,
        toDateTime(1704067200 + ((number * 7937 + 86400 * 365) % 26000000)) AS st,
        toUInt32(60 + (number * 13 % 8000)) AS dur_sec,
        toFloat32(0.1 + abs(sin(toFloat64(number + 1))) * 120 + (rand64() % 5000) / 200.0) AS dist_km,
        arrayElement(
            ['Moscow', 'Saint Petersburg', 'Kazan', 'Novosibirsk', 'Yekaterinburg'],
            toUInt8(1 + (number % 5))
        ) AS city_name
    FROM numbers(1000000)
);
