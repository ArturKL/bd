docker compose:


services:
  influxdb3:
    image: influxdb:3-core
    container_name: influxdb3-core
    command:
      - influxdb3
      - serve
      - --node-id=node0
      - --object-store=file
      - --data-dir=/var/lib/influxdb3/data
    ports:
      - "8181:8181"
    volumes:
      - ./influxdb3-data:/var/lib/influxdb3/data
    restart: unless-stopped

  explorer:
    image: influxdata/influxdb3-ui:1.7.0
    container_name: influxdb3-explorer
    depends_on:
      - influxdb3
    command: ["--mode=admin"]
    ports:
      - "8888:8080"
    volumes:
      - ./explorer-db:/db
      - ./config:/app-root/config:ro
    environment:
      SESSION_SECRET_KEY: ${SESSION_SECRET_KEY:-changeme123456789012345678901234}
    restart: unless-stopped



# InfluxDB 3 + UI (инструкция с нуля до первого запроса)

## 0) Что нужно заранее
- Установлен Docker Desktop.
- Docker запущен (иконка в трее активна).
- Ты находишься в папке, где лежит `docker-compose.yml`.

## 1) Запуск докера
```powershell
docker compose up -d
```

## 2) Проверка, что контейнеры поднят
```powershell
docker compose ps
```

Должны быть `running`:
- `influxdb3-core`
- `influxdb3-explorer`

## 3) Получить админ-токен (без него ничего не сделаешь)

```powershell
docker exec -it influxdb3-core influxdb3 create token --admin
```

Скопируй значение токена и сохрани (например в заметки).  

## 4) Создать первую базу данных

```powershell
curl.exe -X POST "http://localhost:8181/api/v3/configure/database" -H "Content-Type: application/json" -H "Authorization: Bearer ТВОЙ_ТОКЕН" -d "{\"db\":\"mydb\"}"
```

## 5) Записать тестовые данные
```powershell
curl.exe "http://localhost:8181/api/v3/write_lp?db=mydb" -H "Authorization: Bearer ТВОЙ_ТОКЕН" --data-raw "cpu,host=pc1 usage=12.5"
```

## 6) Проверить чтение данных SQL-запросом
```powershell
curl.exe -G "http://localhost:8181/api/v3/query_sql" -H "Authorization: Bearer ТВОЙ_ТОКЕН" --data-urlencode "db=mydb" --data-urlencode "q=SELECT * FROM cpu LIMIT 10"
```

## 7) Запуск UI
1. Открой в браузере: http://localhost:8888
2. Нажми кнопку добавления подключения (`Add connection` / `Create connection`).
3. Заполни поля:
   - `Server URL`: `http://influxdb3:8181`
   - `Server name`: 
   - `Token`: токен из шага 3
4. Нажми `Add server`.
5. Перейди в раздел запроса (`Query Data` -> `Data Explorer`).
6. Вставь тестовый SQL:

```sql
SELECT * FROM cpu LIMIT 10;
```

7. Нажми `Run` (или `Execute`) и проверь, что видишь строку с `host=pc1` и `usage=12.5`.

