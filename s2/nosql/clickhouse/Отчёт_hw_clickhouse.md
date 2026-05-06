## 1. Запуск ClickHouse в Docker

### Файл `docker-compose.yml`

```yaml
services:
  clickhouse:
    image: clickhouse/clickhouse-server:24
    ports:
      - "8123:8123"
      - "9000:9000"
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
```

### Команды

```powershell
cd c:\Users\artur\DataGripProjects\bd\s2\nosql\clickhouse
docker compose up -d
```

## 2. Создание таблицы `trips`

Полный скрипт создания и наполнения — в файле **`hw.sql`**

### Запуск SQL из контейнера

```powershell
docker cp c:\Users\artur\DataGripProjects\bd\s2\nosql\clickhouse\hw.sql clickhouse-clickhouse-1:/tmp/hw.sql
docker exec clickhouse-clickhouse-1 clickhouse-client --multiquery --queries-file /tmp/hw.sql
```

---

## 3. Наполнение: 1 000 000 строк

Данные сгенерированы одним **`INSERT INTO ... SELECT ... FROM numbers(1000000)`**:

- `trip_id`: значения `1` … `1_000_000` (`toUInt32(number + 1)`).
- `start_time` / `end_time`: псевдослучайная длительность в допустимом диапазоне секунд (через `toIntervalSecond`).
- `distance_km`: положительное `Float32` из детерминированной и псевдослучайной части.
- `city`: равномерное распределение по пяти городам через `arrayElement` и `number % 5`.

**Проверка количества строк:**

```powershell
docker exec clickhouse-clickhouse-1 clickhouse-client -q "SELECT count() FROM hw.trips"
```

## 4. Аналитический запрос

Для каждого города выводятся:

- **`avg_distance`** — средняя дистанция (`avg(distance_km)`);
- **`trip_count`** — число поездок (`count()`);
- **`max_duration_sec`** — максимальная длительность поездки в секундах (`max(dateDiff('second', start_time, end_time))`).

Текст запроса в **`hw-analytics.sql`**.

```sql
SELECT
    city,
    avg(distance_km) AS avg_distance,
    count() AS trip_count,
    max(dateDiff('second', start_time, end_time)) AS max_duration_sec
FROM hw.trips
GROUP BY city
ORDER BY city;
```

**Запуск:**

```powershell
docker exec clickhouse-clickhouse-1 clickhouse-client -q "SELECT city, round(avg(distance_km), 6) AS avg_distance, count() AS trip_count, max(dateDiff('second', start_time, end_time)) AS max_duration_sec FROM hw.trips GROUP BY city ORDER BY city FORMAT PrettyCompact"
```

**вывод:**

```text
   ┌─city─────────────┬─avg_distance─┬─trip_count─┬─max_duration_sec─┐
1. │ Kazan            │     88.98967 │     200000 │             8056 │
2. │ Moscow           │    88.995535 │     200000 │             8055 │
3. │ Novosibirsk      │    88.992659 │     200000 │             8059 │
4. │ Saint Petersburg │    88.972353 │     200000 │             8058 │
5. │ Yekaterinburg    │    89.002156 │     200000 │             8057 │
   └──────────────────┴──────────────┴────────────┴──────────────────┘
```
