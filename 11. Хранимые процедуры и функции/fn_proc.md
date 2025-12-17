# Процедуры и функции (финальная модель)

В финальной модели проекта:

- `flow` — поток по **одной** дисциплине (`flow.discipline_id`)
- `enrollment` — запись студента **в поток** (`enrollment.user_id`, `enrollment.flow_id`)
- Допустимые статусы зачисления: `active` / `dropped` / `completed`

> Важно: в таблице `enrollment` **нет столбца** `discipline_id`, статус `enrolled` **запрещён**.

---

## Процедура: enroll_user_in_flow

Записывает студента в поток с проверками: пользователь существует, поток активен, не превышен лимит мест, нет дубля.

```sql
CREATE OR REPLACE PROCEDURE enroll_user_in_flow(
    p_user_id BIGINT,
    p_flow_id BIGINT,
    p_enrolled_at TIMESTAMPTZ DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_exists INT;
    v_status VARCHAR;
    v_max INT;
    v_current INT;
BEGIN
    -- Проверяем, есть ли пользователь
    PERFORM 1 FROM "user" WHERE id = p_user_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id;
    END IF;

    -- Проверяем статус потока
    SELECT status, max_students INTO v_status, v_max
    FROM flow WHERE id = p_flow_id;

    IF v_status <> 'active' THEN
        RAISE EXCEPTION 'Flow % is not active', p_flow_id;
    END IF;

    -- Проверяем, нет ли уже записи (user_id, flow_id)
    SELECT COUNT(*) INTO v_exists
    FROM enrollment
    WHERE user_id = p_user_id AND flow_id = p_flow_id;

    IF v_exists > 0 THEN
        RAISE EXCEPTION 'User % already has an enrollment in flow %', p_user_id, p_flow_id;
    END IF;

    -- Проверяем наличие мест
    SELECT COUNT(*) INTO v_current
    FROM enrollment WHERE flow_id = p_flow_id;

    IF v_current >= v_max THEN
        RAISE EXCEPTION 'Flow % is full', p_flow_id;
    END IF;

    -- Записываем пользователя в поток
    INSERT INTO enrollment(user_id, flow_id, enrolled_at, status)
    VALUES (p_user_id, p_flow_id, COALESCE(p_enrolled_at, now()), 'active');

    RAISE NOTICE 'User % successfully added to flow %', p_user_id, p_flow_id;
END;
$$;
```

Пример вызова (как в `SQL_QUERIES_FOR_DEFENSE.sql`):

```sql
DELETE FROM enrollment WHERE user_id = 15 AND flow_id = 3;
CALL enroll_user_in_flow(15, 3, TIMESTAMPTZ '2025-01-20 10:30:00+03');

SELECT id, user_id, flow_id, status, enrolled_at
FROM enrollment
WHERE user_id = 15 AND flow_id = 3;
```

---

## Функция: student_avg_score

Возвращает средний балл студента по всем его зачислениям (учитываются только `current_score IS NOT NULL`).

```sql
CREATE OR REPLACE FUNCTION student_avg_score(p_user_id BIGINT)
    RETURNS NUMERIC(6, 2) AS
$$
BEGIN
    RETURN (
        SELECT CASE
            WHEN COUNT(*) = 0 THEN 0
            ELSE AVG(current_score)
        END
        FROM enrollment
        WHERE user_id = p_user_id
          AND current_score IS NOT NULL
    );
END;
$$ LANGUAGE plpgsql STABLE;
```

Пример вызова:

```sql
SELECT
    id,
    full_name,
    student_avg_score(id) AS avg_score
FROM "user"
WHERE id IN (SELECT DISTINCT user_id FROM enrollment)
ORDER BY student_avg_score(id) DESC, id;
```
