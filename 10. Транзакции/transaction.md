# Транзакции (финальная модель)

В финальной модели:

- студент записывается **в поток** (`enrollment.flow_id`), а дисциплина определяется через `flow.discipline_id`
- статусы `enrollment.status`: `active` / `dropped` / `completed`

Ниже — пример из раздела **G** файла `SQL_QUERIES_FOR_DEFENSE.sql`.

---

## G) BEGIN + COMMIT (атомарное добавление студента и зачисление)

```sql
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
```

---

## G) BEGIN + ROLLBACK (пример отката)

```sql
BEGIN;

INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Тестовый Студент', 'test@university.edu', 1, 'active');

ROLLBACK;

-- Проверка: записи нет
SELECT COUNT(*) AS test_user_count
FROM "user"
WHERE email = 'test@university.edu';
```
