-- Проверки для router (postgres_fdw + HASH-партиции). Подставьте БД router_db.
SELECT count(*) AS users_on_router FROM "user";

EXPLAIN (VERBOSE, COSTS OFF)
SELECT *
FROM "user"
WHERE id = 1;

EXPLAIN (VERBOSE, COSTS OFF)
SELECT *
FROM "user"
ORDER BY id;
