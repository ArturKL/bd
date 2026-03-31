# Секционирование

Добавил partition в миграции

## RANGE

```postgresql
EXPLAIN ANALYZE
SELECT * FROM enrollment
WHERE enrolled_at >= '2024-01-01'
  AND enrolled_at < '2025-01-01';
```
| QUERY PLAN |
| :--- |
| Seq Scan on enrollment\_2024 enrollment  \(cost=0.00..5194.00 rows=83583 width=362\) \(actual time=0.015..13.280 rows=83600 loops=1\) |
|   Filter: \(\(enrolled\_at &gt;= '2024-01-01 00:00:00+00'::timestamp with time zone\) AND \(enrolled\_at &lt; '2025-01-01 00:00:00+00'::timestamp with time zone\)\) |
| Planning Time: 0.651 ms |
| Execution Time: 15.536 ms |

```postgresql
EXPLAIN ANALYZE
SELECT * FROM enrollment
WHERE enrolled_at >= '2024-01-01'
  AND enrolled_at < '2025-06-01';
```
| QUERY PLAN |
| :--- |
| Append  \(cost=0.00..10935.75 rows=117835 width=362\) \(actual time=0.009..35.817 rows=117978 loops=1\) |
|   -&gt;  Seq Scan on enrollment\_2024 enrollment\_1  \(cost=0.00..5194.00 rows=83583 width=362\) \(actual time=0.008..16.501 rows=83600 loops=1\) |
|         Filter: \(\(enrolled\_at &gt;= '2024-01-01 00:00:00+00'::timestamp with time zone\) AND \(enrolled\_at &lt; '2025-06-01 00:00:00+00'::timestamp with time zone\)\) |
|   -&gt;  Seq Scan on enrollment\_2025 enrollment\_2  \(cost=0.00..5152.58 rows=34252 width=362\) \(actual time=0.015..12.116 rows=34378 loops=1\) |
|         Filter: \(\(enrolled\_at &gt;= '2024-01-01 00:00:00+00'::timestamp with time zone\) AND \(enrolled\_at &lt; '2025-06-01 00:00:00+00'::timestamp with time zone\)\) |
|         Rows Removed by Filter: 48594 |
| Planning Time: 0.433 ms |
| Execution Time: 39.536 ms |

## LIST

```postgresql
EXPLAIN ANALYZE
SELECT *
FROM flow
WHERE status = 'active';
```
| QUERY PLAN |
| :--- |
| Seq Scan on flow\_active flow  \(cost=0.00..4999.18 rows=83054 width=471\) \(actual time=0.060..31.847 rows=83054 loops=1\) |
|   Filter: \(\(status\)::text = 'active'::text\) |
| Planning Time: 0.280 ms |
| Execution Time: 34.080 ms |

## HASH
```postgresql
EXPLAIN ANALYZE
SELECT *
FROM "user"
WHERE id = 123;
```
| QUERY PLAN |
| :--- |
| Index Scan using user\_p0\_pkey on user\_p0 "user"  \(cost=0.29..8.31 rows=1 width=810\) \(actual time=0.032..0.033 rows=1 loops=1\) |
|   Index Cond: \(id = 123\) |
| Planning Time: 0.530 ms |
| Execution Time: 0.057 ms |
