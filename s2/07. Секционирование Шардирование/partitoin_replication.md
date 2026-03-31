# Секционирование: физическая и логическая репликация
## Конфигурация Docker

Поднимаются три экземпляра PostgreSQL 16 из `docker-compose.yml`:

| Роль | Контейнер | Порт с хоста |
|------|-----------|----------------|
| Primary (источник правды, публикации, миграции V1–V5) | `pg_primary` | 15432 |
| Физическая реплика (streaming standby) | `pg_replica_physical` | 15433 |
| Логический подписчик (подписка `course_sub` на `course_pub`) | `pg_logical_sub` | 15434 |


## 1. Секционирование и физическая репликация

### Проверка: секционирование есть на реплике

На primary и на standby одна и та же иерархия в `pg_inherits` (родитель и листья совпадают)

```postgresql
course_db=# SELECT c.relname AS parent, c2.relname AS partition
FROM pg_inherits i
JOIN pg_class c ON c.oid = i.inhparent
JOIN pg_class c2 ON c2.oid = i.inhrelid
WHERE c.relname IN ('enrollment', 'flow', 'user')
ORDER BY 1, 2;
   parent   |    partition     
------------+------------------
 enrollment | enrollment_2023
 enrollment | enrollment_2024
 enrollment | enrollment_2025
 enrollment | enrollment_2026
 enrollment | enrollment_other
 flow       | flow_active
 flow       | flow_archived
 flow       | flow_other
 user       | user_p0
 user       | user_p1
 user       | user_p2
 user       | user_p3
(12 rows)
```

### Почему репликация «не знает» про секции

Репликация не "знает" о секциях,
так как она работает на уровне WAL-записей,
а не на уровне SQL-операций.

Выбор секции происходит только на primary,
а реплика просто воспроизводит уже выполненные изменения.


## 2. Логическая репликация и `publish_via_partition_root`

Публикация создаётся миграцией **V5** на primary (`db/migrations/V5__logical_publication.sql`):

```postgresql
CREATE PUBLICATION course_pub FOR ALL TABLES WITH (publish_via_partition_root = true);
CREATE PUBLICATION course_pub_no_root FOR ALL TABLES WITH (publish_via_partition_root = false);
```

Имена таблиц, которые относятся к публикации (каталог):

```postgresql
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'course_pub'
  AND tablename IN ('enrollment', 'flow', 'user', 'user_p0', 'enrollment_2024')
ORDER BY tablename;
```
| schemaname | tablename |
| :--- | :--- |
| public | enrollment |
| public | flow |
| public | user |

```postgresql
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'course_pub_no_root'
  AND tablename IN ('enrollment', 'flow', 'user', 'user_p0', 'enrollment_2024')
ORDER BY tablename;
```
| schemaname | tablename |
| :--- | :--- |
| public | enrollment\_2024 |
| public | user\_p0 |

При **`publish_via_partition_root = on`** в этом представлении отображаются корневые секционированные таблицы (`enrollment`, `flow`, `user`), а не отдельные листья вроде `user_p0` или `enrollment_2024`. Изменения по листьям при доставке на подписчик описываются в терминах корня (идентичность и схема родителя), что согласуется с таким же деревом партиций на подписчике.

При **`publish_via_partition_root = off`** публикация оперирует фактическими реляциями-листьями; в `pg_publication_tables` появляются партиции. Подписчик должен иметь совместимые листья и принимать события под их именами.
