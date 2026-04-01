```postgresql
analyze;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, shop_id, total_sum, sold_at
FROM store_checks
WHERE shop_id = 77
  AND sold_at >= TIMESTAMP '2025-02-14 00:00:00'
  AND sold_at < TIMESTAMP '2025-02-15 00:00:00';
```
| QUERY PLAN |
| :--- |
| Seq Scan on store\_checks  \(cost=0.00..1880.07 rows=1 width=26\) \(actual time=4.188..4.190 rows=3 loops=1\) |
|   Filter: \(\(sold\_at &gt;= '2025-02-14 00:00:00'::timestamp without time zone\) AND \(sold\_at &lt; '2025-02-15 00:00:00'::timestamp without time zone\) AND \(shop\_id = 77\)\) |
|   Rows Removed by Filter: 70001 |
|   Buffers: shared hit=655 |
| Planning: |
|   Buffers: shared hit=31 |
| Planning Time: 0.117 ms |
| Execution Time: 4.206 ms |

2) Seq Scan. 
Никакой индекс не помогает idx_store_checks_total_sum_hash и idx_store_checks_payment_type индексируют поля которые не используются в запросе. 
Нет индекса, поэтому фулл скан

```postgresql
CREATE INDEX idx_store_checks_shop_id ON store_checks(shop_id);
analyze;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, shop_id, total_sum, sold_at
FROM store_checks
WHERE shop_id = 77
  AND sold_at >= TIMESTAMP '2025-02-14 00:00:00'
  AND sold_at < TIMESTAMP '2025-02-15 00:00:00';
```
| QUERY PLAN |
| :--- |
| Bitmap Heap Scan on store\_checks  \(cost=4.95..247.43 rows=1 width=26\) \(actual time=0.116..0.117 rows=3 loops=1\) |
|   Recheck Cond: \(shop\_id = 77\) |
|   Filter: \(\(sold\_at &gt;= '2025-02-14 00:00:00'::timestamp without time zone\) AND \(sold\_at &lt; '2025-02-15 00:00:00'::timestamp without time zone\)\) |
|   Rows Removed by Filter: 89 |
|   Heap Blocks: exact=89 |
|   Buffers: shared hit=89 read=2 |
|   -&gt;  Bitmap Index Scan on idx\_store\_checks\_shop\_id  \(cost=0.00..4.95 rows=87 width=0\) \(actual time=0.024..0.025 rows=92 loops=1\) |
|         Index Cond: \(shop\_id = 77\) |
|         Buffers: shared read=2 |
| Planning: |
|   Buffers: shared hit=18 read=1 |
| Planning Time: 0.302 ms |
| Execution Time: 0.140 ms |

Используется Bitmap Heap Scan - т.е. испрользуется индекс

Нужно выполнить потому что появился индекс, планировщику нужно пересчитать

## Задание 2
```postgresql
EXPLAIN (ANALYZE, BUFFERS)
SELECT m.id, m.member_level, v.spend, v.visit_at
FROM club_members m
JOIN club_visits v ON v.member_id = m.id
WHERE m.member_level = 'premium'
  AND v.visit_at >= TIMESTAMP '2025-02-01 00:00:00'
  AND v.visit_at < TIMESTAMP '2025-02-10 00:00:00';
```
| QUERY PLAN |
| :--- |
| Hash Join  \(cost=691.74..1804.78 rows=739 width=27\) \(actual time=2.361..5.365 rows=819 loops=1\) |
|   Hash Cond: \(v.member\_id = m.id\) |
|   Buffers: shared hit=1112 |
|   -&gt;  Bitmap Heap Scan on club\_visits v  \(cost=234.42..1318.25 rows=11122 width=22\) \(actual time=0.585..2.438 rows=10998 loops=1\) |
|         Recheck Cond: \(\(visit\_at &gt;= '2025-02-01 00:00:00'::timestamp without time zone\) AND \(visit\_at &lt; '2025-02-10 00:00:00'::timestamp without time zone\)\) |
|         Heap Blocks: exact=917 |
|         Buffers: shared hit=948 |
|         -&gt;  Bitmap Index Scan on idx\_club\_visits\_visit\_at  \(cost=0.00..231.64 rows=11122 width=0\) \(actual time=0.507..0.508 rows=10998 loops=1\) |
|               Index Cond: \(\(visit\_at &gt;= '2025-02-01 00:00:00'::timestamp without time zone\) AND \(visit\_at &lt; '2025-02-10 00:00:00'::timestamp without time zone\)\) |
|               Buffers: shared hit=31 |
|   -&gt;  Hash  \(cost=439.00..439.00 rows=1466 width=13\) \(actual time=1.751..1.752 rows=1466 loops=1\) |
|         Buckets: 2048  Batches: 1  Memory Usage: 85kB |
|         Buffers: shared hit=164 |
|         -&gt;  Seq Scan on club\_members m  \(cost=0.00..439.00 rows=1466 width=13\) \(actual time=0.008..1.576 rows=1466 loops=1\) |
|               Filter: \(member\_level = 'premium'::text\) |
|               Rows Removed by Filter: 20534 |
|               Buffers: shared hit=164 |
| Planning: |
|   Buffers: shared hit=6 |
| Planning Time: 0.172 ms |
| Execution Time: 5.416 ms |

Используется Hash Join,
на club_visits есть индекс idx_club_visits_visit_at, а таблица club_members хэшируется для джоина

```postgresql
CREATE INDEX idx_club_members_member_level ON club_members(member_level);
ANALYZE ;
EXPLAIN (ANALYZE, BUFFERS)
SELECT m.id, m.member_level, v.spend, v.visit_at
FROM club_members m
JOIN club_visits v ON v.member_id = m.id
WHERE m.member_level = 'premium'
  AND v.visit_at >= TIMESTAMP '2025-02-01 00:00:00'
  AND v.visit_at < TIMESTAMP '2025-02-10 00:00:00';
```
| QUERY PLAN |
| :--- |
| Hash Join  \(cost=455.36..1569.51 rows=745 width=27\) \(actual time=1.409..3.872 rows=819 loops=1\) |
|   Hash Cond: \(v.member\_id = m.id\) |
|   Buffers: shared hit=1112 read=3 |
|   -&gt;  Bitmap Heap Scan on club\_visits v  \(cost=235.06..1319.84 rows=11185 width=22\) \(actual time=0.609..2.102 rows=10998 loops=1\) |
|         Recheck Cond: \(\(visit\_at &gt;= '2025-02-01 00:00:00'::timestamp without time zone\) AND \(visit\_at &lt; '2025-02-10 00:00:00'::timestamp without time zone\)\) |
|         Heap Blocks: exact=917 |
|         Buffers: shared hit=948 |
|         -&gt;  Bitmap Index Scan on idx\_club\_visits\_visit\_at  \(cost=0.00..232.27 rows=11185 width=0\) \(actual time=0.532..0.532 rows=10998 loops=1\) |
|               Index Cond: \(\(visit\_at &gt;= '2025-02-01 00:00:00'::timestamp without time zone\) AND \(visit\_at &lt; '2025-02-10 00:00:00'::timestamp without time zone\)\) |
|               Buffers: shared hit=31 |
|   -&gt;  Hash  \(cost=201.97..201.97 rows=1466 width=13\) \(actual time=0.789..0.790 rows=1466 loops=1\) |
|         Buckets: 2048  Batches: 1  Memory Usage: 85kB |
|         Buffers: shared hit=164 read=3 |
|         -&gt;  Bitmap Heap Scan on club\_members m  \(cost=19.65..201.97 rows=1466 width=13\) \(actual time=0.092..0.597 rows=1466 loops=1\) |
|               Recheck Cond: \(member\_level = 'premium'::text\) |
|               Heap Blocks: exact=164 |
|               Buffers: shared hit=164 read=3 |
|               -&gt;  Bitmap Index Scan on idx\_club\_members\_member\_level  \(cost=0.00..19.28 rows=1466 width=0\) \(actual time=0.069..0.070 rows=1466 loops=1\) |
|                     Index Cond: \(member\_level = 'premium'::text\) |
|                     Buffers: shared read=3 |
| Planning: |
|   Buffers: shared hit=23 read=1 |
| Planning Time: 0.415 ms |
| Execution Time: 3.931 ms |

Идет фильтр по m.member_level --> сделали для него индекс, теперь вместо Seq Scan идет Bitmap Heap Scan on club_members m

Shared hit означает, что были использованы страницы буфера для получения строк

## Задание 3
```postgresql
SELECT xmin, xmax, ctid, id, title, stock
FROM warehouse_items
ORDER BY id;
```
| xmin | xmax | ctid | id | title | stock |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 754 | 0 | \(0,1\) | 1 | Cable | 40 |
| 754 | 0 | \(0,2\) | 2 | Adapter | 25 |
| 754 | 0 | \(0,3\) | 3 | Hub | 12 |

```postgresql
UPDATE warehouse_items
SET stock = stock - 2
WHERE id = 1;

SELECT xmin, xmax, ctid, id, title, stock
FROM warehouse_items
ORDER BY id;
```
| xmin | xmax | ctid | id | title | stock |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 952 | 0 | \(0,4\) | 1 | Cable | 38 |
| 754 | 0 | \(0,2\) | 2 | Adapter | 25 |
| 754 | 0 | \(0,3\) | 3 | Hub | 12 |

```postgresql
DELETE FROM warehouse_items
WHERE id = 3;

SELECT xmin, xmax, ctid, id, title, stock
FROM warehouse_items
ORDER BY id;
```
| xmin | xmax | ctid | id | title | stock |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 952 | 0 | \(0,4\) | 1 | Cable | 38 |
| 754 | 0 | \(0,2\) | 2 | Adapter | 25 |

1) Обновился xmin на номер транзакции update'а, строка в страницах теперь на позиции 4 вместо 1
2) Когда произошел апдейт, у старай строки поменялся xmax (то есть она помечена как мертвая)
и была добавлена новая обновленная строка
3) delete изменил xmax удаленной строки на номер транзакции её удалившей
номер транзакции в которой проходит select выше xmax, поэтому он её не видит как будто строка была удалена
4)
- VACUUM находит мертвые строки и помечает место занимаемое ими как свободное, чтобы туда можно было записывать новые строки, но место ОС не возвращает, индексы не пересчитываются
- autovacuum в фоне регулярно выполняет VACUUM и ANALYZE
- VACUUM FULL очищает мертвые строки и уплотняет записи, возвращая место ОС, и пересчитывает индексы
5) VACUUM FULL для полной очистки полностью блокирует таблицу

## Задание 4
```bash
course_db=# BEGIN;
SELECT * FROM booking_slots WHERE id = 1 FOR KEY SHARE;
BEGIN
 id | room_code | reserved_count 
----+-----------+----------------
  1 | A101      |              1
(1 row)

course_db=*# ROLLBACK;
ROLLBACK
```

```bash
course_db=# DELETE FROM booking_slots
WHERE id = 1;
DELETE 1
```

1) В Б апдейт ждет транзакцию А, выполняет делит только после роллбэка в А

```bash
course_db=*# ROLLBACK;
ROLLBACK
course_db=# BEGIN;
SELECT * FROM booking_slots WHERE id = 1 FOR NO KEY UPDATE;
BEGIN
```

Селект не происходит потому что транзакция B внесла изменения в строку, но еще не закоммитила
