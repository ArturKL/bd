ANALYZE;

EXPLAIN ANALYZE
SELECT *
FROM enrollment
WHERE enrolled_at >= '2024-01-01'
  AND enrolled_at < '2025-01-01';

EXPLAIN ANALYZE
SELECT *
FROM enrollment
WHERE enrolled_at >= '2024-01-01'
  AND enrolled_at < '2025-06-01';

EXPLAIN ANALYZE
SELECT *
FROM flow
WHERE status = 'active';

EXPLAIN ANALYZE
SELECT *
FROM "user"
WHERE id = 123;

CREATE PUBLICATION course_pub FOR ALL TABLES WITH (publish_via_partition_root = true);

CREATE PUBLICATION course_pub_no_root FOR ALL TABLES WITH (publish_via_partition_root = false);

SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'course_pub'
  AND tablename IN ('enrollment', 'flow', 'user', 'user_p0', 'enrollment_2024')
ORDER BY tablename;

SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'course_pub_no_root'
  AND tablename IN ('enrollment', 'flow', 'user', 'user_p0', 'enrollment_2024')
ORDER BY tablename;