## 1) Запуск Compose

Из папки `nosql\influxdb`:

```powershell
cd c:\Users\artur\DataGripProjects\bd\s2\nosql\influxdb
docker compose up -d
docker compose ps
```
---

## 2) Админ-токен

```powershell
docker exec -it influxdb3-core influxdb3 create token --admin
```

Скопируйте строку после `Token:` и подставляйте вместо **`$TOKEN`** в командах ниже (или вынесите в переменную):

```powershell
$TOKEN = 'apiv3_AQWBA1vzZjyR6HsrNahTBoW1m8j5x8NOddL7wiDaqd-7fi12AuyuMD-kdKe0CP2paVxEE6MIMZEB65AQW6jd5Q'

---

## 3) Bucket / база данных `mydb`

```powershell
curl.exe -X POST "http://localhost:8181/api/v3/configure/database" `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $TOKEN" `
  -d "{\"db\":\"mydb\"}"
```

**Ожидание:** HTTP **200**.

---

## 4) Запись данных (Line Protocol), measurement `temperature`

```powershell
curl.exe "http://localhost:8181/api/v3/write_lp?db=mydb" `
  -H "Authorization: Bearer $TOKEN" `
  --data-raw "temperature,location=room1 value=23"
```

Выполнены вставки **пяти точек**: чередование `room1`/`room2` и значения `23`, `19.5`, `22.8`, `20.1`, `24` — с **уникальными** временными метками (через PowerShell-сценарий с `--data-raw` и приращением времени между строками).

```powershell
$TOKEN = 'apiv3_AQWBA1vzZjyR6HsrNahTBoW1m8j5x8NOddL7wiDaqd-7fi12AuyuMD-kdKe0CP2paVxEE6MIMZEB65AQW6jd5Q'
$i = 0
@( 
  @{ loc='room1'; v=23 }
  @{ loc='room2'; v=19.5 }
  @{ loc='room1'; v=22.8 }
  @{ loc='room2'; v=20.1 }
  @{ loc='room1'; v=24 }
) | ForEach-Object {
  $i++
  $ns = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000L + ($i * 1000L)
  $ln = "temperature,location=$($_.loc) value=$($_.v) $ns"
  curl.exe -s -o NUL -w "HTTP:%{http_code} $ln`n" -X POST "http://localhost:8181/api/v3/write_lp?db=mydb" -H "Authorization: Bearer $TOKEN" --data-raw $ln
  Start-Sleep -Milliseconds 50
}

HTTP:204 temperature,location=room1 value=23 1778026649284001000
HTTP:204 temperature,location=room2 value=19.5 1778026649993002000
HTTP:204 temperature,location=room1 value=22.8 1778026650932003000
HTTP:204 temperature,location=room2 value=20.1 1778026651931004000
HTTP:204 temperature,location=room1 value=24 1778026652932005000
```

---

## 5) Чтение: `SELECT`

```powershell
curl.exe -G "http://localhost:8181/api/v3/query_sql" `
  -H "Authorization: Bearer $TOKEN" `
  --data-urlencode "db=mydb" `
  --data-urlencode "q=SELECT * FROM temperature LIMIT 20"
```

```
[{"n":7}][{"location":"room1","time":"2026-05-06T00:17:15.103098274","value":24.0},{"location":"room2","time":"2026-05-06T00:17:15.103098274","value":20.1},{"location":"room1","time":"2026-05-06T00:17:29.284001","value":23.0},{"location":"room2","time":"2026-05-06T00:17:29.993002","value":19.5},{"location":"room1","time":"2026-05-06T00:17:30.932003","value":22.8},{"location":"room2","time":"2026-05-06T00:17:31.931004","value":20.1},{"location":"room1","time":"2026-05-06T00:17:32.932005","value":24.0}]
```

---

## 6) Данные за последние 5 минут

```sql
SELECT *
FROM temperature
WHERE time >= now() - INTERVAL '5 minutes'
ORDER BY time;
```

`curl`:

```powershell
curl.exe -G "http://localhost:8181/api/v3/query_sql" `
  -H "Authorization: Bearer $TOKEN" `
  --data-urlencode "db=mydb" `
  --data-urlencode "q=SELECT * FROM temperature WHERE time >= now() - INTERVAL '5 minutes' ORDER BY time"
```

```json
[{"location":"room1","time":"2026-05-06T00:17:15.103098274","value":24.0},{"location":"room2","time":"2026-05-06T00:17:15.103098274","value":20.1},{"location":"room1","time":"2026-05-06T00:17:29.284001","value":23.0},{"location":"room2","time":"2026-05-06T00:17:29.993002","value":19.5},{"location":"room1","time":"2026-05-06T00:17:30.932003","value":22.8},{"location":"room2","time":"2026-05-06T00:17:31.931004","value":20.1},{"location":"room1","time":"2026-05-06T00:17:32.932005","value":24.0}]
```

---

## 7) Группировка по тегу `location` — среднее `value`

```sql
SELECT
    location,
    AVG(value) AS avg_value
FROM temperature
WHERE time >= now() - INTERVAL '5 minutes'
GROUP BY location
ORDER BY location;
```

`curl`:

```powershell
curl.exe -G "http://localhost:8181/api/v3/query_sql" `
  -H "Authorization: Bearer $TOKEN" `
  --data-urlencode "db=mydb" `
  --data-urlencode "q=SELECT location, AVG(value) AS avg_value FROM temperature WHERE time >= now() - INTERVAL '5 minutes' GROUP BY location ORDER BY location"
```

**Фактический ответ последнего прогона:**

```json
[
  {"location":"room1","avg_value":23.45},
  {"location":"room2","avg_value":19.900000000000002}
]
```
