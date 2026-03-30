## Сетап реплик:

- `docker stop pg_replica1`
- `docker run --rm -it -v replica1_data:/var/lib/postgresql/data postgres:16 bash`
- `rm -rf /var/lib/postgresql/data/*`
-
`docker run --rm -it --network db_course_sem2_default -v db_course_sem2_replica1_data:/var/lib/postgresql/data postgres:16 pg_basebackup -h primary -D /var/lib/postgresql/data -U replicator -P -R`

## Проверка

```postgresql
SELECT *
FROM pg_stat_replication;
```

### На мастере

| pid | usesysid | usename    | application\_name | client\_addr | client\_hostname | client\_port | backend\_start                    | backend\_xmin | state     | sent\_lsn | write\_lsn | flush\_lsn | replay\_lsn | write\_lag                                         | flush\_lag                                         | replay\_lag                                        | sync\_priority | sync\_state | reply\_time                       |
|:----|:---------|:-----------|:------------------|:-------------|:-----------------|:-------------|:----------------------------------|:--------------|:----------|:----------|:-----------|:-----------|:------------|:---------------------------------------------------|:---------------------------------------------------|:---------------------------------------------------|:---------------|:------------|:----------------------------------|
| 66  | 16388    | replicator | walreceiver       | 172.18.0.3   | null             | 51260        | 2026-03-29 21:33:02.945919 +00:00 | null          | streaming | 0/5000060 | 0/5000060  | 0/5000060  | 0/5000060   | 0 years 0 mons 0 days 0 hours 0 mins 0.163541 secs | 0 years 0 mons 0 days 0 hours 0 mins 0.171854 secs | 0 years 0 mons 0 days 0 hours 0 mins 0.171973 secs | 0              | async       | 2026-03-29 21:33:54.960053 +00:00 |
| 73  | 16388    | replicator | walreceiver       | 172.18.0.4   | null             | 51480        | 2026-03-29 21:33:56.964317 +00:00 | null          | streaming | 0/5000060 | 0/5000060  | 0/5000060  | 0/5000060   | 0 years 0 mons 0 days 0 hours 0 mins 0.148174 secs | 0 years 0 mons 0 days 0 hours 0 mins 0.157002 secs | 0 years 0 mons 0 days 0 hours 0 mins 0.157008 secs | 0              | async       | 2026-03-29 21:33:57.130712 +00:00 |

```postgresql
INSERT INTO role (code, name, status)
VALUES ('admin', 'Administrator', 'ACTIVE'),
       ('student', 'Student', 'ACTIVE'),
       ('teacher', 'Teacher', 'ACTIVE')
ON CONFLICT (code)
    DO UPDATE SET name   = EXCLUDED.name,
                  status = EXCLUDED.status;
```

### На реплике

```
PS C:\Users\artur\DataGripProjects\db_course_sem2> docker exec -it pg_replica1 psql -U admin -d course_db
psql (16.12 (Debian 16.12-1.pgdg13+1))
Type "help" for help.

course_db=# SELECT * FROM role;
 id |  code   |     name      | description | is_system | status |          created_at           |          updated_at           
----+---------+---------------+-------------+-----------+--------+-------------------------------+-------------------------------
  1 | admin   | Administrator |             | f         | ACTIVE | 2026-03-29 21:38:27.904526+00 | 2026-03-29 21:38:27.904526+00
  2 | student | Student       |             | f         | ACTIVE | 2026-03-29 21:38:27.904526+00 | 2026-03-29 21:38:27.904526+00
  3 | teacher | Teacher       |             | f         | ACTIVE | 2026-03-29 21:38:27.904526+00 | 2026-03-29 21:38:27.904526+00
(3 rows)

course_db=# INSERT INTO role (code, name, status)
VALUES ('admin', 'Administrator', 'ACTIVE'),
       ('student', 'Student', 'ACTIVE'),
       ('teacher', 'Teacher', 'ACTIVE');
ERROR:  cannot execute INSERT in a read-only transaction
```

## Lag

Запустил `fill_data.sql` на мастере (1млн инсертов)

На реплике:

```
course_db=# SELECT now() - pg_last_xact_replay_timestamp();
    ?column?     
-----------------
 00:01:11.105436
(1 row)
```

## Logical replication

### На мастере

```postgresql
CREATE ROLE replicator WITH LOGIN REPLICATION PASSWORD 'pass';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO replicator;

CREATE TABLE test_logical
(
    id   SERIAL PRIMARY KEY,
    name TEXT
);
INSERT INTO test_logical(name)
VALUES ('one'),
       ('two'),
       ('three');
CREATE PUBLICATION my_pub FOR TABLE test_logical;

INSERT INTO test_logical(name) VALUES ('four');
```

### На реплике

```postgresql
CREATE TABLE test_logical
(
    id   SERIAL PRIMARY KEY,
    name TEXT
);

CREATE SUBSCRIPTION my_sub
    CONNECTION 'host=primary port=5432 user=replicator password=pass dbname=course_db'
    PUBLICATION my_pub;

SELECT * FROM test_logical;
```
| id | name |
| :--- | :--- |
| 1 | one |
| 2 | two |
| 3 | three |
| 4 | four |

### на мастере
```postgresql
ALTER TABLE test_logical ADD COLUMN age INT;
INSERT INTO test_logical(name, age) VALUES ('five', 1);
```

### на реплике
```
2026-03-30 01:55:46.514 UTC [506] LOG:  logical replication apply worker for subscription "my_sub" has started
2026-03-30 01:55:46.527 UTC [506] ERROR:  logical replication target relation "public.test_logical" is missing replicated column: "age"
2026-03-30 01:55:46.527 UTC [506] CONTEXT:  processing remote data for replication origin "pg_16416" during message type "INSERT" in transaction 763, finished at 0/19A1C58
2026-03-30 01:55:46.530 UTC [1] LOG:  background worker "logical replication worker" (PID 506) exited with exit code 1
```

### мастер
```postgresql
CREATE TABLE no_pk (
    name TEXT
);
INSERT INTO no_pk VALUES ('A');
UPDATE no_pk SET name = 'B';
```
```
ERROR:  cannot update table "no_pk" because it does not have a replica identity and publishes updates
HINT:  To enable updating the table, set REPLICA IDENTITY using ALTER TABLE.
```

```postgresql
ALTER TABLE no_pk REPLICA IDENTITY FULL;
UPDATE no_pk SET name = 'B';
```

### реплика
```
course_db=# select * from no_pk;
 name 
------
 A
(1 row)

course_db=# select * from no_pk;
 name 
------
 B
(1 row)
```

```
course_db=# SELECT * FROM pg_stat_subscription;
 subid | subname | pid | leader_pid | relid | received_lsn |      last_msg_send_time       |     last_msg_receipt_time     | latest_end_lsn |        latest_end_time        
-------+---------+-----+------------+-------+--------------+-------------------------------+-------------------------------+----------------+-------------------------------
 16430 | my_sub  | 573 |            |       | 0/19C3B80    | 2026-03-30 02:04:51.629597+00 | 2026-03-30 02:04:51.629718+00 | 0/19C3B80      | 2026-03-30 02:04:51.629597+00
(1 row)
```

```
course_db=# SELECT * FROM pg_stat_replication;
 pid | usesysid |  usename   | application_name | client_addr | client_hostname | client_port |         backend_start         | backend_xmin |   state   | sent_lsn  | write_lsn | flush_lsn | replay_lsn | write_lag | flush_lag | replay_lag | sync_priority | sync_state |          reply_time           
-----+----------+------------+------------------+-------------+-----------------+-------------+-------------------------------+--------------+-----------+-----------+-----------+-----------+------------+-----------+-----------+------------+---------------+------------+-------------------------------
 584 |    16401 | replicator | my_sub           | 172.18.0.3  |                 |       36226 | 2026-03-30 02:00:07.859694+00 |              | streaming | 0/19C3B80 | 0/19C3B80 | 0/19C3B80 | 0/19C3B80  |           |           |            |             0 | async      | 2026-03-30 02:06:11.720028+00
(1 row)
```

pg_dump / pg_restore удобен чтобы перенести cхему с мастера на реплику. 
