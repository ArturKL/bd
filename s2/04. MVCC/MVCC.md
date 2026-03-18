# 1. Смоделировать обновление данных и посмотреть на параметры xmin, xmax, ctid, t_infomask
```postgresql
SELECT xmin, xmax, ctid, * FROM role;
```
| xmin | xmax | ctid | id | code | name | description | is\_system | status | created\_at | updated\_at |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 755 | 0 | \(0,1\) | 1 | admin | Administrator | null | false | ACTIVE | 2026-03-17 23:50:01.495516 +00:00 | 2026-03-17 23:50:01.495516 +00:00 |
| 755 | 0 | \(0,2\) | 2 | student | Student | null | false | ACTIVE | 2026-03-17 23:50:01.495516 +00:00 | 2026-03-17 23:50:01.495516 +00:00 |
| 755 | 0 | \(0,3\) | 3 | teacher | Teacher | null | false | ACTIVE | 2026-03-17 23:50:01.495516 +00:00 | 2026-03-17 23:50:01.495516 +00:00 |
---
```postgresql
UPDATE role SET is_system = true WHERE code = 'admin';
SELECT xmin, xmax, ctid, * FROM role;
```
| xmin | xmax | ctid | id | code | name | description | is\_system | status | created\_at | updated\_at |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 755 | 0 | \(0,2\) | 2 | student | Student | null | false | ACTIVE | 2026-03-17 23:50:01.495516 +00:00 | 2026-03-17 23:50:01.495516 +00:00 |
| 755 | 0 | \(0,3\) | 3 | teacher | Teacher | null | false | ACTIVE | 2026-03-17 23:50:01.495516 +00:00 | 2026-03-17 23:50:01.495516 +00:00 |
| 757 | 0 | \(0,4\) | 1 | admin | Administrator | null | true | ACTIVE | 2026-03-17 23:50:01.495516 +00:00 | 2026-03-17 23:50:01.495516 +00:00 |
---
```postgresql
CREATE EXTENSION IF NOT EXISTS pageinspect;
SELECT lp, t_xmin, t_xmax, t_ctid, t_infomask
FROM heap_page_items(get_raw_page('role', 0));
```
| lp | t\_xmin | t\_xmax | t\_ctid | t\_infomask |
| :--- | :--- | :--- | :--- | :--- |
| 1 | 755 | 757 | \(0,4\) | 1283 |
| 2 | 755 | 0 | \(0,2\) | 2307 |
| 3 | 755 | 0 | \(0,3\) | 2307 |
| 4 | 757 | 0 | \(0,4\) | 10499 |

t_infomask — это битовая маска, где хранится:
- committed / not committed
- updated / deleted
- lock flags
- visibility flags

# Транзакции
### Session 1:
```shell
course_db=# BEGIN;
BEGIN
course_db=*# SELECT txid_current();
 txid_current 
--------------
          761
(1 row)

course_db=*# SELECT xmin, xmax, ctid, code, name FROM role;
 xmin | xmax | ctid  |  code   |     name      
------+------+-------+---------+---------------
  755 |    0 | (0,2) | student | Student
  755 |    0 | (0,3) | teacher | Teacher
  760 |    0 | (0,5) | admin   | Administrator
(3 rows)

course_db=*# UPDATE role SET description = 'Student' WHERE code = 'student';
UPDATE 1
course_db=*# SELECT xmin, xmax, ctid, code, name FROM role;
 xmin | xmax | ctid  |  code   |     name      
------+------+-------+---------+---------------
  755 |    0 | (0,3) | teacher | Teacher
  760 |    0 | (0,5) | admin   | Administrator
  761 |    0 | (0,6) | student | Student
(3 rows)

course_db=*# 
```

### Session 2:
```shell
course_db=# BEGIN;
BEGIN
course_db=*# SELECT txid_current();
 txid_current 
--------------
          762
(1 row)

course_db=*# SELECT xmin, xmax, ctid, code, name, description FROM role;
 xmin | xmax | ctid  |  code   |     name      | description 
------+------+-------+---------+---------------+-------------
  755 |  761 | (0,2) | student | Student       | 
  755 |    0 | (0,3) | teacher | Teacher       | 
  760 |    0 | (0,5) | admin   | Administrator | Student
(3 rows)
```

### Session 1:
```shell
course_db=*# commit;
COMMIT
```
### Session 2:
```shell
course_db=*# SELECT xmin, xmax, ctid, code, name, description FROM role;
 xmin | xmax | ctid  |  code   |     name      | description 
------+------+-------+---------+---------------+-------------
  755 |    0 | (0,3) | teacher | Teacher       | 
  760 |    0 | (0,5) | admin   | Administrator | Student
  761 |    0 | (0,6) | student | Student       | Student
(3 rows)
```

# Deadlock
### Session 1:
```shell
course_db=# begin;
BEGIN
course_db=*# SELECT txid_current();
 txid_current 
--------------
          764
(1 row)

course_db=*# UPDATE role SET name = 'Admin S1' WHERE code = 'admin';
UPDATE 1
course_db=*# UPDATE role SET name = 'Student S1' WHERE code = 'student';
UPDATE 1
course_db=*# commit;
COMMIT
```
### Session 2:
```shell
course_db=*# commit;
COMMIT
course_db=# begin;
BEGIN
course_db=*# SELECT txid_current();
 txid_current 
--------------
          765
(1 row)

course_db=*# UPDATE role SET name = 'Student S2' WHERE code = 'student';
UPDATE 1
course_db=*# UPDATE role SET name = 'Admin S2' WHERE code = 'admin';
ERROR:  deadlock detected
DETAIL:  Process 3982 waits for ShareLock on transaction 764; blocked by process 5232.
Process 5232 waits for ShareLock on transaction 765; blocked by process 3982.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,8) in relation "role"
course_db=!# commit;
ROLLBACK
```

```shell
course_db-# select * from role;
 id |  code   |    name    | description | is_system | status |          created_at           |          updated_at           
----+---------+------------+-------------+-----------+--------+-------------------------------+-------------------------------
  3 | teacher | Teacher    |             | f         | ACTIVE | 2026-03-17 23:50:01.495516+00 | 2026-03-17 23:50:01.495516+00
  1 | admin   | Admin S1   |             | t         | ACTIVE | 2026-03-17 23:50:01.495516+00 | 2026-03-17 23:50:01.495516+00
  2 | student | Student S1 |             | f         | ACTIVE | 2026-03-17 23:50:01.495516+00 | 2026-03-17 23:50:01.495516+00
(3 rows)
```

# Блокировка строк
## FOR UPDATE
### Session 1:
```shell
course_db=# begin;
BEGIN
course_db=*# SELECT * FROM role WHERE code = 'admin' FOR UPDATE;
 id | code  |   name   | description | is_system | status |          created_at           |          updated_at           
----+-------+----------+-------------+-----------+--------+-------------------------------+-------------------------------
  1 | admin | Admin S1 |             | t         | ACTIVE | 2026-03-17 23:50:01.495516+00 | 2026-03-17 23:50:01.495516+00
(1 row)
```
### Session 2:
```shell
course_db=# UPDATE role SET name = 'Blocked' WHERE code = 'admin';
-- зависла --
```
## FOR SHARE
### Session 1:
```shell
course_db=# begin;
BEGIN
course_db=*# SELECT * FROM role WHERE code = 'admin' FOR SHARE;
 id | code  |  name   | description | is_system | status |          created_at           |          updated_at           
----+-------+---------+-------------+-----------+--------+-------------------------------+-------------------------------
  1 | admin | Blocked |             | t         | ACTIVE | 2026-03-17 23:50:01.495516+00 | 2026-03-17 23:50:01.495516+00
(1 row)
```
### Session 2:
```shell
course_db=# SELECT * FROM role WHERE code = 'admin' FOR SHARE;
 id | code  |  name   | description | is_system | status |          created_at           |          updated_at           
----+-------+---------+-------------+-----------+--------+-------------------------------+-------------------------------
  1 | admin | Blocked |             | t         | ACTIVE | 2026-03-17 23:50:01.495516+00 | 2026-03-17 23:50:01.495516+00
(1 row)
-- работает --
course_db=# UPDATE role SET name = 'test' WHERE code = 'admin';
-- зависла --
```

# Очистка
```shell
course_db=# SELECT lp, t_xmin, t_xmax, t_ctid
FROM heap_page_items(get_raw_page('role', 0));
 lp | t_xmin | t_xmax | t_ctid 
----+--------+--------+--------
  1 |    781 |      0 | (0,1)
  2 |    781 |      0 | (0,2)
  3 |    781 |      0 | (0,3)
(3 rows)

course_db=# UPDATE role SET name = 'v1';
UPDATE role SET name = 'v2';
UPDATE role SET name = 'v3';
UPDATE 3
UPDATE 3
UPDATE 3
course_db=# SELECT lp, t_xmin, t_xmax, t_ctid
FROM heap_page_items(get_raw_page('role', 0));
 lp | t_xmin | t_xmax | t_ctid 
----+--------+--------+--------
  1 |    781 |    783 | (0,4)
  2 |    781 |    783 | (0,5)
  3 |    781 |    783 | (0,6)
  4 |    783 |    784 | (0,7)
  5 |    783 |    784 | (0,8)
  6 |    783 |    784 | (0,9)
  7 |    784 |    785 | (0,10)
  8 |    784 |    785 | (0,11)
  9 |    784 |    785 | (0,12)
 10 |    785 |      0 | (0,10)
 11 |    785 |      0 | (0,11)
 12 |    785 |      0 | (0,12)
(12 rows)

course_db=# VACUUM role;
VACUUM
course_db=# SELECT lp, t_xmin, t_xmax, t_ctid
FROM heap_page_items(get_raw_page('role', 0));
 lp | t_xmin | t_xmax | t_ctid 
----+--------+--------+--------
  1 |        |        | 
  2 |        |        | 
  3 |        |        | 
  4 |        |        | 
  5 |        |        | 
  6 |        |        | 
  7 |        |        | 
  8 |        |        | 
  9 |        |        | 
 10 |    785 |      0 | (0,10)
 11 |    785 |      0 | (0,11)
 12 |    785 |      0 | (0,12)
(12 rows)

course_db=# VACUUM FULL role;
VACUUM
course_db=# SELECT lp, t_xmin, t_xmax, t_ctid
FROM heap_page_items(get_raw_page('role', 0));
 lp | t_xmin | t_xmax | t_ctid 
----+--------+--------+--------
  1 |    785 |      0 | (0,1)
  2 |    785 |      0 | (0,2)
  3 |    785 |      0 | (0,3)
(3 rows)

```