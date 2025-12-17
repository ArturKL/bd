-- Транзакции (финальная модель)
--
-- enrollment хранит (user_id, flow_id, status, enrolled_at, current_score, ...)
-- Допустимые статусы: active / dropped / completed

-- G1) COMMIT: добавить студента + зачислить в поток
BEGIN;

INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Новый Студент', 'newstudent@university.edu', 1, 'active')
ON CONFLICT (email) DO UPDATE
SET full_name = EXCLUDED.full_name,
    unit_id = EXCLUDED.unit_id,
    status = EXCLUDED.status;

INSERT INTO enrollment (user_id, flow_id, status, enrolled_at)
VALUES (
    (SELECT id FROM "user" WHERE email = 'newstudent@university.edu'),
    3,
    'active',
    TIMESTAMPTZ '2025-01-20 10:30:00+03'
) ON CONFLICT (user_id, flow_id) DO UPDATE
SET status = EXCLUDED.status,
    enrolled_at = EXCLUDED.enrolled_at;

COMMIT;

-- Проверка результата
SELECT id, full_name, email FROM "user" WHERE email = 'newstudent@university.edu';
SELECT id, user_id, flow_id, status, enrolled_at
FROM enrollment
WHERE user_id = (SELECT id FROM "user" WHERE email = 'newstudent@university.edu');

-- G2) ROLLBACK: пример отката
BEGIN;

INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Тестовый Студент', 'test@university.edu', 1, 'active');

ROLLBACK;

-- Проверка: записи нет
SELECT COUNT(*) AS test_user_count
FROM "user"
WHERE email = 'test@university.edu';
