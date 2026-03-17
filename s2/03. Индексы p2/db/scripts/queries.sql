ANALYZE;

CREATE INDEX IF NOT EXISTS idx_user_interests ON "user" USING GIN (interests);

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
from "user"
where interests @> ARRAY ['cs', 'music'];

CREATE INDEX idx_user_bio ON "user" USING GIN (to_tsvector('english', bio));

EXPLAIN ANALYZE
SELECT *
FROM "user"
WHERE to_tsvector('english', bio) @@ to_tsquery('english', 'database & network');

CREATE INDEX idx_lesson_materials ON lesson USING GIN (materials jsonb_ops);

DROP INDEX idx_lesson_materials;

EXPLAIN ANALYZE
SELECT *
FROM lesson
WHERE materials @> '{"access_level": "staff"}';

EXPLAIN ANALYZE
SELECT *
FROM lesson
WHERE materials ? 'resources';

CREATE INDEX idx_enrollment_progress ON enrollment USING GIN (progress);

DROP INDEX idx_enrollment_progress;
EXPLAIN ANALYZE
SELECT *
FROM enrollment
WHERE progress @> '{"badges_earned": ["perfect_score"]}';

CREATE INDEX idx_flow_active_range ON flow USING GIST (active_range);
DROP INDEX idx_flow_active_range;
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM flow
WHERE active_range && '[2026-06-15,2026-07-30]'::daterange;

CREATE INDEX idx_user_active_period ON "user" USING GIST (active_period);
DROP INDEX idx_user_active_period;
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM "user"
WHERE active_period @> '2025-05-15 12:00:00+03'::timestamptz;

CREATE INDEX idx_user_location ON "user" USING GIST (home_location);
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM "user"
ORDER BY home_location <-> point '(55.75, 37.61)'
LIMIT 10;
DROP INDEX idx_user_location;
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM "user"
WHERE home_location <@ circle '((55.75, 37.61), 10)';

CREATE INDEX idx_enrollment_attendance_range ON enrollment USING GIST (attendance_range);
DROP INDEX idx_enrollment_attendance_range;
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM enrollment
WHERE attendance_range @> 95.0;

EXPLAIN (ANALYZE, BUFFERS)
SELECT u.full_name,
       u.email,
       e.current_score,
       e.final_grade,
       e.status AS enrollment_status
FROM enrollment e
         JOIN "user" u ON e.user_id = u.id
         JOIN flow f ON e.flow_id = f.id
WHERE f.code = 'FL1';

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    u.full_name,
    f.title AS flow_name,
    e.attendance_pct,
    e.current_score
FROM enrollment e
JOIN "user" u ON e.user_id = u.id
JOIN flow f ON e.flow_id = f.id
WHERE e.attendance_pct < 50.0
  AND e.current_score > 85.0
  AND e.status = 'active';

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    u.full_name,
    l.topic,
    l.materials->>'access_level' AS access_level,
    l.materials->'resources' AS resources_list
FROM enrollment e
JOIN "user" u ON e.user_id = u.id
JOIN flow f ON e.flow_id = f.id
JOIN lesson l ON l.flow_id = f.id
WHERE e.status = 'active'
  AND l.materials IS NOT NULL
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    f.title AS flow_title,
    u.full_name,
    u.email,
    COALESCE(e.attendance_pct, 0) AS attendance
FROM flow f
JOIN enrollment e ON e.flow_id = f.id
JOIN "user" u ON e.user_id = u.id
LEFT JOIN lesson l ON l.flow_id = f.id
    -- Попытка найти хотя бы одно посещение (логика зависит от того, как считается attendance_pct)
WHERE (e.attendance_pct IS NULL OR e.attendance_pct = 0)
  AND f.status = 'active';

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    u.full_name,
    f.title,
    e.progress->>'current_module' AS current_module
FROM enrollment e
JOIN "user" u ON e.user_id = u.id
JOIN flow f ON e.flow_id = f.id
WHERE e.progress ? 'badges_earned'
  AND f.cohort_year = 2023;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    u.full_name,
    u.last_login_at,
    f.title AS flow_name,
    e.status AS enrollment_status,
    MIN(l.start_at) AS next_lesson_time,
    MIN(l.topic) AS next_lesson_topic
FROM "user" u
JOIN enrollment e ON u.id = e.user_id
JOIN flow f ON e.flow_id = f.id
JOIN lesson l ON l.flow_id = f.id
WHERE u.id = 54321
  AND e.status = 'active'
  AND l.start_at > NOW()
GROUP BY u.full_name, u.last_login_at, f.title, e.status;