## 1) SELECT + CASE (2 запроса)
  
### 1.1 Студенты, потоки и уровень посещаемости (CASE по `attendance_pct`)

```sql

SELECT

u.id,

u.full_name,

f.code AS flow_code,

e.attendance_pct,

CASE

WHEN e.attendance_pct >= 90 THEN 'высокая'

WHEN e.attendance_pct >= 70 THEN 'средняя'

WHEN e.attendance_pct IS NULL THEN 'нет данных'

ELSE 'низкая'

END AS attendance_level

FROM enrollment e

JOIN "user" u ON u.id = e.user_id

JOIN flow f ON f.id = e.flow_id

ORDER BY u.full_name, f.code;

```

РЕЗУЛЬТАТ — ![[Pasted image 20251015101059.png]]

  

### 1.2 Экзамены и «временной статус» (CASE по времени и `status`)

```sql

SELECT

ex.id,

ex.type,

ex.scheduled_start,

ex.scheduled_end,

ex.status,

CASE

WHEN ex.status = 'canceled' THEN 'отменён'

WHEN now() < ex.scheduled_start THEN 'запланирован'

WHEN now() BETWEEN ex.scheduled_start AND ex.scheduled_end THEN 'идёт сейчас'

WHEN now() > ex.scheduled_end THEN 'завершён'

ELSE 'неизвестно'

END AS time_state

FROM exam ex

ORDER BY ex.scheduled_start NULLS LAST;

```

РЕЗУЛЬТАТ — ![[Pasted image 20251015101110.png]]

  
  

---

  

## 2) JOIN (по 2 запроса на каждый вид)

  

### 2.1 INNER JOIN — вариант A: «студент → поток → дисциплина» через `enrollment`

```sql

SELECT

u.full_name AS student,

d.code AS discipline_code,

d.title AS discipline_title,

f.code AS flow_code

FROM enrollment e

JOIN "user" u ON u.id = e.user_id

JOIN flow f ON f.id = e.flow_id

JOIN discipline d ON d.id = e.discipline_id

ORDER BY u.full_name, d.code;

```

РЕЗУЛЬТАТ — ![[Pasted image 20251015101121.png]]

  

### 2.2 INNER JOIN — вариант B: задания по потокам (есть только где есть задания)

```sql

SELECT

f.code AS flow_code,

f.title AS flow_title,

COUNT(a.id) AS assignments_count

FROM flow f

JOIN assignment a ON a.flow_id = f.id

GROUP BY f.id, f.code, f.title

ORDER BY assignments_count DESC, f.code;

```

РЕЗУЛЬТАТ — ![[Pasted image 20251015101135.png]]

  
  

### 2.3 LEFT JOIN — вариант A: все пользователи с их ролью

```sql

SELECT

u.id,

u.full_name,

r.code AS role_code,

r.name AS role_name

FROM "user" u

LEFT JOIN role r ON r.id = u.role_id

ORDER BY u.full_name;

```

РЕЗУЛЬТАТ — ![[Pasted image 20251015101146.png]]

  

### 2.4 LEFT JOIN — вариант B: все потоки и количество студентов (0 допускается)

```sql

SELECT

f.id,

f.code,

f.title,

COALESCE(COUNT(e.user_id), 0) AS students_count

FROM flow f

LEFT JOIN enrollment e ON e.flow_id = f.id

GROUP BY f.id, f.code, f.title

ORDER BY students_count DESC, f.code;

```

РЕЗУЛЬТАТ — ![[Pasted image 20251015101208.png]]

  
  

### 2.5 RIGHT JOIN — вариант A: показать все потоки, даже без студентов

```sql

SELECT

f.code AS flow_code,

COALESCE(COUNT(e.user_id), 0) AS students_count

FROM enrollment e

RIGHT JOIN flow f ON f.id = e.flow_id

GROUP BY f.id, f.code

ORDER BY f.code;

```

РЕЗУЛЬТАТ — ![[Pasted image 20251015101222.png]]

  

### 2.6 RIGHT JOIN — вариант B: показать все роли, даже если ни одному пользователю не назначено

```sql

SELECT

r.code AS role_code,

r.name AS role_name,

COUNT(u.id) AS users_with_role

FROM "user" u

RIGHT JOIN role r ON r.id = u.role_id

GROUP BY r.id, r.code, r.name

ORDER BY r.code;

```

РЕЗУЛЬТАТ — ![[Pasted image 20251015101233.png]]

  
  

### 2.7 CROSS JOIN — вариант A: декартово произведение «роль × статус пользователя»

```sql

SELECT

r.code AS role_code,

r.name AS role_name,

s.status

FROM role r

CROSS JOIN (

SELECT DISTINCT status FROM "user"

) AS s

ORDER BY r.code, s.status;

```

РЕЗУЛЬТАТ — ![[Pasted image 20251015101246.png]]

  

### 2.8 CROSS JOIN — вариант B: «типы занятий × дни недели» (полезно для отчёта-шаблона)

```sql

WITH lesson_types AS (

SELECT unnest(ARRAY['lecture','seminar','lab']) AS ltype

),

dow AS (

SELECT unnest(ARRAY['Mon','Tue','Wed','Thu','Fri','Sat','Sun']) AS day_short

)

SELECT lt.ltype, d.day_short

FROM lesson_types lt

CROSS JOIN dow d

ORDER BY lt.ltype, d.day_short;

```

РЕЗУЛЬТАТ — ![[Pasted image 20251015101305.png]]

  
  

### 2.9 FULL OUTER JOIN — вариант A: аудитории и факты использования занятиями

```sql

SELECT

c.id AS classroom_id,

c.building,

c.room_number,

l.id AS lesson_id,

l.start_at

FROM classroom c

FULL OUTER JOIN lesson l ON l.auditorium_id = c.id

ORDER BY c.building NULLS FIRST, c.room_number NULLS FIRST, l.start_at NULLS LAST;

```

РЕЗУЛЬТАТ — ![[Pasted image 20251015101316.png]]

  

### 2.10 FULL OUTER JOIN — вариант B: экзамены и прокторы (покажем всё с обеих сторон)

```sql

SELECT

ex.id AS exam_id,

ex.type,

ex.scheduled_start,

ex.scheduled_end,

p.full_name AS proctor_name

FROM exam ex

FULL OUTER JOIN "user" p ON p.id = ex.proctor_id

ORDER BY ex.scheduled_start NULLS LAST, proctor_name NULLS LAST;

```

РЕЗУЛЬТАТ — ![[Pasted image 20251015101325.png]]