```pgsql
ANALYZE;
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM flow WHERE status='active';
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM flow WHERE cohort_year in ('2022', '2024', '2026');
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM enrollment WHERE attendance_pct < 50;
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM "user" WHERE phone LIKE '+1231%';
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM "user" WHERE phone LIKE '+%21';
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM "user" WHERE phone='+123122333';
```
## Flow status
```postgresql
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM flow WHERE status='active';
```
### без индекса
| QUERY PLAN |
| :--- |
| Seq Scan on flow  \(cost=0.00..11745.00 rows=84067 width=0\) \(actual time=0.011..53.216 rows=83249 loops=1\) |
|   Filter: \(\(status\)::text = 'active'::text\) |
|   Rows Removed by Filter: 166751 |
|   Buffers: shared hit=7127 read=1493 |
| Planning: |
|   Buffers: shared hit=16 |
| Planning Time: 0.077 ms |
| Execution Time: 56.420 ms |

### c индексом
| QUERY PLAN |
| :--- |
| Index Only Scan using idx\_flow\_status on flow  \(cost=0.42..1763.59 rows=84067 width=0\) \(actual time=0.023..5.591 rows=83249 loops=1\) |
|   Index Cond: \(status = 'active'::text\) |
|   Heap Fetches: 0 |
|   Buffers: shared hit=74 |
| Planning Time: 0.093 ms |
| Execution Time: 7.915 ms |

```
Index Only Scan ~7x быстрее Seq Scan
```



## flow cohort year
```postgresql
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM flow WHERE cohort_year in ('2022', '2024', '2026');
```
### без индекса
| QUERY PLAN |
| :--- |
| Seq Scan on flow  \(cost=0.00..12057.50 rows=50442 width=0\) \(actual time=0.008..38.057 rows=50087 loops=1\) |
|   Filter: \(cohort\_year = ANY \('{2022,2024,2026}'::integer\[\]\)\) |
|   Rows Removed by Filter: 199913 |
|   Buffers: shared hit=7176 read=1444 |
| Planning: |
|   Buffers: shared hit=15 |
| Planning Time: 0.179 ms |
| Execution Time: 39.710 ms |

### с индексом
| QUERY PLAN |
| :--- |
| Index Only Scan using idx\_flow\_cohort\_year on flow  \(cost=0.42..1048.00 rows=50442 width=0\) \(actual time=0.072..3.529 rows=50087 loops=1\) |
|   Index Cond: \(cohort\_year = ANY \('{2022,2024,2026}'::integer\[\]\)\) |
|   Heap Fetches: 0 |
|   Buffers: shared hit=5 read=46 |
| Planning: |
|   Buffers: shared hit=16 read=1 |
| Planning Time: 0.184 ms |
| Execution Time: 4.962 ms |
```
Index Only Scan ~8x быстрее Seq Scan
```

## enrollment attendance
```postgresql
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM enrollment WHERE attendance_pct < 50;
```
### без индекса
| QUERY PLAN |
| :--- |
| Seq Scan on enrollment  \(cost=0.00..9223.00 rows=124987 width=0\) \(actual time=0.010..46.755 rows=125281 loops=1\) |
|   Filter: \(attendance\_pct &lt; '50'::numeric\) |
|   Rows Removed by Filter: 124719 |
|   Buffers: shared hit=109 read=5989 |
| Planning Time: 0.053 ms |
| Execution Time: 50.389 ms |


### с индексом
| QUERY PLAN |
| :--- |
| Index Only Scan using idx\_enrollment\_attendance on enrollment  \(cost=0.42..3567.69 rows=124987 width=0\) \(actual time=0.029..17.081 rows=125281 loops=1\) |
|   Index Cond: \(attendance\_pct &lt; '50'::numeric\) |
|   Heap Fetches: 0 |
|   Buffers: shared hit=346 |
| Planning Time: 0.060 ms |
| Execution Time: 21.463 ms |
```
Index Only Scan ~2.4x быстрее Seq Scan
```


## user phone like%
```postgresql
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM "user" WHERE phone LIKE '+1231%';
```
### без индекса
| QUERY PLAN |
| :--- |
| Seq Scan on "user"  \(cost=0.00..11647.00 rows=94237 width=0\) \(actual time=9.301..114.016 rows=94580 loops=1\) |
|   Filter: \(\(phone\)::text \~\~ '+1231%'::text\) |
|   Rows Removed by Filter: 155420 |
|   Buffers: shared hit=5976 read=2546 |
| Planning: |
|   Buffers: shared hit=6 dirtied=1 |
| Planning Time: 0.081 ms |
| Execution Time: 116.678 ms |

### с индексом
| QUERY PLAN |
| :--- |
| Index Only Scan using idx\_user\_phone on "user"  \(cost=0.42..7783.42 rows=94237 width=0\) \(actual time=0.019..65.131 rows=94580 loops=1\) |
|   Filter: \(\(phone\)::text \~\~ '+1231%'::text\) |
|   Rows Removed by Filter: 155420 |
|   Heap Fetches: 0 |
|   Buffers: shared hit=848 |
| Planning Time: 0.073 ms |
| Execution Time: 70.627 ms |
```
Index Only Scan ~1.6x быстрее Seq Scan
```


## user phone %like
```postgresql
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM "user" WHERE phone LIKE '+%21';
```
### без индекса
| QUERY PLAN |
| :--- |
| Gather  \(cost=1000.00..10826.18 rows=21 width=0\) \(actual time=4.695..210.947 rows=2128 loops=1\) |
|   Workers Planned: 2 |
|   Workers Launched: 2 |
|   Buffers: shared hit=6035 read=2487 |
|   -&gt;  Parallel Seq Scan on "user"  \(cost=0.00..9824.08 rows=9 width=0\) \(actual time=1.670..177.210 rows=709 loops=3\) |
|         Filter: \(\(phone\)::text \~\~ '+%21'::text\) |
|         Rows Removed by Filter: 82624 |
|         Buffers: shared hit=6035 read=2487 |
| Planning: |
|   Buffers: shared hit=6 |
| Planning Time: 0.359 ms |
| Execution Time: 211.877 ms |

### с индексом
| QUERY PLAN |
| :--- |
| Gather  \(cost=1000.42..6962.60 rows=21 width=0\) \(actual time=1.409..101.198 rows=2128 loops=1\) |
|   Workers Planned: 2 |
|   Workers Launched: 2 |
|   Buffers: shared hit=6 read=844 |
|   -&gt;  Parallel Index Only Scan using idx\_user\_phone on "user"  \(cost=0.42..5960.50 rows=9 width=0\) \(actual time=0.498..81.102 rows=709 loops=3\) |
|         Filter: \(\(phone\)::text \~\~ '+%21'::text\) |
|         Rows Removed by Filter: 82624 |
|         Heap Fetches: 0 |
|         Buffers: shared hit=6 read=844 |
| Planning Time: 0.203 ms |
| Execution Time: 101.681 ms |
```
Parallel Index Only Scan ~2x быстрее Parallel Seq Scan
```


## user phone =
```postgresql
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM "user" WHERE phone='+123122333';
```
### без индекса
| QUERY PLAN |
| :--- |
| Gather  \(cost=1000.00..10824.18 rows=1 width=0\) \(actual time=31.874..49.992 rows=1 loops=1\) |
|   Workers Planned: 2 |
|   Workers Launched: 2 |
|   Buffers: shared hit=6291 read=2231 |
|   -&gt;  Parallel Seq Scan on "user"  \(cost=0.00..9824.08 rows=1 width=0\) \(actual time=21.406..28.365 rows=0 loops=3\) |
|         Filter: \(\(phone\)::text = '+123122333'::text\) |
|         Rows Removed by Filter: 83333 |
|         Buffers: shared hit=6291 read=2231 |
| Planning Time: 0.063 ms |
| Execution Time: 50.023 ms |

### с b-tree индексом
| QUERY PLAN |
| :--- |
| Index Only Scan using idx\_user\_phone on "user"  \(cost=0.42..4.44 rows=1 width=0\) \(actual time=0.028..0.029 rows=1 loops=1\) |
|   Index Cond: \(phone = '+123122332'::text\) |
|   Heap Fetches: 0 |
|   Buffers: shared hit=4 |
| Planning Time: 0.071 ms |
| Execution Time: 0.043 ms |

### с hash индексом
| QUERY PLAN |
| :--- |
| Index Scan using idx\_user\_phone\_hash on "user"  \(cost=0.00..8.02 rows=1 width=0\) \(actual time=0.014..0.014 rows=1 loops=1\) |
|   Index Cond: \(\(phone\)::text = '+123122332'::text\) |
|   Buffers: shared hit=2 |
| Planning Time: 0.060 ms |
| Execution Time: 0.025 ms |

```
B-tree Index Only Scan ~1000x быстрее Parallel Seq Scan
Hash Index Scan ~2x быстрее B-tree Index Only Scan
```