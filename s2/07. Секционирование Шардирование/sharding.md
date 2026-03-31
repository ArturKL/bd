# Шардирование через `postgres_fdw`: таблица `"user"` и HASH-партиции

Задание: **два шарда** (отдельные PostgreSQL) и **один router**, где логически одна таблица **`"user"`** как в `V1__init_tables.sql` секционирована **`PARTITION BY HASH (id)`** на **две партиции**, и **каждая партиция** — это **`postgres_fdw`** к физической таблице `"user"` на своём шарде.

Стек репликации курса (primary, standby, logical) **не затрагивается** — свои тома и порты.

---

## Архитектура в Docker

| Узел | Сервис | Контейнер | БД | Порт |
|------|--------|-----------|-----|------|
| Router | `postgres-router` | `pg_router_fdw` | `router_db` | **15440** |
| Шард 1 (остаток HASH % 2 = 0) | `postgres-shard1` | `pg_shard1` | `shard_db` | **15441** |
| Шард 2 (остаток HASH % 2 = 1) | `postgres-shard2` | `pg_shard2` | `shard_db` | **15442** |

### 1. Шарды

Файлы `docker/sharding/shard1/01-init.sql` и `shard2/01-init.sql`:

- Таблица **`unit`**
- Таблица **`"user"`** — с **`PRIMARY KEY (id)`** на шарде.

На шарде **нет** `PARTITION BY`: это обычная таблица; «шардирование» задаётся тем, что **через router** в эту таблицу попадают только строки, относящиеся к соответствующему остатку `HASH(id)`.

### 2. Router

Файл `docker/sharding/router/01-fdw.sql`:

1. **`CREATE EXTENSION postgres_fdw`**, два **`SERVER`** (`postgres-shard1`, `postgres-shard2`), **`USER MAPPING`** для `admin`.
2. **`CREATE TABLE "user" (...) PARTITION BY HASH (id)`**
3. **`CREATE FOREIGN TABLE user_p0 PARTITION OF "user" FOR VALUES WITH (MODULUS 2, REMAINDER 0) SERVER shard1 OPTIONS (table_name 'user', ...)`** — данные с остатком **0** хранятся на **шарде 1**.
4. **`CREATE FOREIGN TABLE user_p1 PARTITION OF "user" ... REMAINDER 1 SERVER shard2`** — остаток **1** → **шард 2**.

Если на родительской секционированной таблице объявить **`PRIMARY KEY (id)`** (или любое глобальное **UNIQUE** на родителе) и при этом партиции — **внешние**, инициализация падает с ошибкой:

```text
ERROR:  cannot create foreign partition of partitioned table "user"
DETAIL:  Table "user" contains indexes that are unique.
```

Поэтому на **router** у родителя **`"user"` нет PK**: глобальная уникальность **`id`** обеспечивается **на каждом шарде** (`PRIMARY KEY (id)` там остаётся).

Также на router **нет** `FOREIGN KEY (unit_id) REFERENCES unit(...)`: справочник `unit` существует только на шардах; в FDW-колонках `unit_id` передаётся как `BIGINT`.

### 3. Загрузка данных через router

Файл `docker/sharding/router/02-seed.sql` выполняется при init **после** `01-fdw.sql`:

- **`INSERT INTO "user" (...)`** с явными `id` и остальными полями.
- PostgreSQL по правилу **`HASH(id) MODULUS 2`** направляет каждую строку в **`user_p0` или `user_p1`** и через FDW выполняет **удалённый INSERT** на нужный шард.

На стенде после загрузки:

```bash
>docker exec -it pg_shard1 psql -U admin -d shard_db           
psql (16.12 (Debian 16.12-1.pgdg13+1))
Type "help" for help.

shard_db=# select * from "user";
 id | full_name |      email      |  phone   | unit_id | student_number | employee_position | status |       created_at       |       updated_at       | last_login_at 
----+-----------+-----------------+----------+---------+----------------+-------------------+--------+------------------------+------------------------+---------------
  1 | Alice     | alice@lab.local | +1000001 |       1 | SN-1           |                   | active | 2026-03-01 10:00:00+00 | 2026-03-01 10:00:00+00 | 
  2 | Bob       | bob@lab.local   | +1000002 |       1 | SN-2           |                   | active | 2026-03-02 11:00:00+00 | 2026-03-02 11:00:00+00 | 
(2 rows)

> docker exec -it pg_shard2 psql -U admin -d shard_db      
psql (16.12 (Debian 16.12-1.pgdg13+1))
Type "help" for help.

shard_db=# select * from "user";
 id | full_name |      email      |  phone   | unit_id | student_number | employee_position |  status  |       created_at       |       updated_at       |     last_login_at      
----+-----------+-----------------+----------+---------+----------------+-------------------+----------+------------------------+------------------------+------------------------
  3 | Carol     | carol@lab.local |          |       1 | SN-3           | TA                | active   | 2026-03-03 12:00:00+00 | 2026-03-03 12:00:00+00 | 2026-03-10 08:00:00+00
  4 | Dan       | dan@lab.local   | +1000004 |       1 | SN-4           |                   | inactive | 2026-03-04 13:00:00+00 | 2026-03-04 13:00:00+00 | 
  5 | Eve       | eve@lab.local   |          |       1 | SN-5           |                   | pending  | 2026-03-05 14:00:00+00 | 2026-03-05 14:00:00+00 | 
(3 rows)
```

```postgresql
INSERT INTO "user" (id, full_name, email, status)
SELECT 
    generate_series(7, 106) AS id,
    'User ' || generate_series(7, 106) AS full_name,
    'user' || generate_series(7, 106) || '@example.com' AS email,
    'active' AS status;
```
```bash
shard_db=#  select count(*) as shard1_count from "user";
 shard1_count 
--------------
           55
(1 row)

shard_db=# select count(*) as shard2_count from "user";
 shard2_count 
--------------
           51
(1 row)
```

### a) Все строки логической таблицы

```postgresql
SELECT *
FROM "user"
ORDER BY id;
```
```bash
router_db=# explain analyze select * from "user" order by id;
                                                       QUERY PLAN                                                        
-------------------------------------------------------------------------------------------------------------------------
 Merge Append  (cost=200.01..202.62 rows=5 width=169) (actual time=1.791..1.805 rows=106 loops=1)
   Sort Key: "user".id
   ->  Foreign Scan on user_p0 user_1  (cost=100.00..101.26 rows=2 width=299) (actual time=0.976..0.979 rows=55 loops=1)
   ->  Foreign Scan on user_p1 user_2  (cost=100.00..101.30 rows=3 width=83) (actual time=0.814..0.816 rows=51 loops=1)
 Planning Time: 0.122 ms
 Execution Time: 2.632 ms
(6 rows)
```

**Смысл:** нужны **обе** партиции; FDW строит **`Merge Append`** (сортировка по `id` сливается с двух шардов). Два удалённых запроса — два сетевых участка.

### b) Запрос на шард

```postgresql
SELECT *
FROM "user"
WHERE id = 1;
```
```bash
router_db=# explain analyze select * from "user" where id = 50;
                                                    QUERY PLAN                                                    
------------------------------------------------------------------------------------------------------------------
 Foreign Scan on user_p0 "user"  (cost=100.00..101.05 rows=1 width=299) (actual time=0.643..0.644 rows=1 loops=1)
 Planning Time: 0.100 ms
 Execution Time: 1.143 ms
(3 rows)

router_db=# explain analyze select * from "user" where id = 5;
                                                   QUERY PLAN                                                    
-----------------------------------------------------------------------------------------------------------------
 Foreign Scan on user_p1 "user"  (cost=100.00..101.06 rows=1 width=83) (actual time=0.632..0.633 rows=1 loops=1)
 Planning Time: 0.095 ms
 Execution Time: 1.113 ms
(3 rows)
```
