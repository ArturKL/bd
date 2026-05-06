## Что подготовлено

В каталоге `nosql/redis` добавлен простейший Docker Compose-проект для Redis (`redis:7-alpine`), контейнер поднят и к нему выполнены все команды из домашней работы.

---

## Часть 1. Запуск Redis и подключение к CLI

### Файл `docker-compose.yml`

```yaml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: ["redis-server", "--appendonly", "yes"]
```

### Команды

```powershell
cd c:\Users\artur\DataGripProjects\bd\s2\nosql\redis
docker compose up -d
```

Имя контейнера после запуска: `redis-redis-1`.

**Проверка, что сервер отвечает:**

```powershell
docker exec redis-redis-1 redis-cli PING
```

**Фактический вывод:** `PONG`

**Подключение к Redis CLI (интерактивно):**

```powershell
docker exec -it redis-redis-1 redis-cli
```

С хост-машины (если установлен `redis-cli` и порт `6379` свободен):

```powershell
redis-cli -h 127.0.0.1 -p 6379
```

---

## Часть 2. Счётчик просмотров статьи

Ключ счётчика: `article:10:views`. Используется строковый ключ с целым значением через `INCR`.

### Команды и вывод

```powershell
docker exec redis-redis-1 redis-cli DEL article:10:views
# (integer) 0  — ключа не было

docker exec redis-redis-1 redis-cli INCR article:10:views
# (integer) 1

docker exec redis-redis-1 redis-cli INCR article:10:views
# (integer) 2

docker exec redis-redis-1 redis-cli INCR article:10:views
# (integer) 3

docker exec redis-redis-1 redis-cli GET article:10:views
# "3"
```

**Текущее значение после трёх просмотров:** `3`.

---

## Часть 3. Рейтинг статей (Sorted Set / leaderboard)

Ключ отсортированного множества: `leaderboard:popular`.  
Участники: `article:1` … `article:4`, в качестве score — число просмотров.

### Заполнение и топ-3

```powershell
docker exec redis-redis-1 redis-cli DEL leaderboard:popular
# (integer) 0

docker exec redis-redis-1 redis-cli ZADD leaderboard:popular 120 article:1 45 article:2 300 article:3 10 article:4
# (integer) 4
```

**Топ-3 без вывода количества просмотров** (по убыванию score):

```powershell
docker exec redis-redis-1 redis-cli ZRANGE leaderboard:popular 0 2 REV
```

Вывод (по одному элементу на строку):

1. `article:3`
2. `article:1`
3. `article:2`

**Топ-3 с количеством просмотров (score):**

```powershell
docker exec redis-redis-1 redis-cli ZRANGE leaderboard:popular 0 2 REV WITHSCORES
```

Пары `member` / `score`:

| Место | Статья     | Просмотры |
|-------|------------|-----------|
| 1     | article:3  | 300       |
| 2     | article:1  | 120       |
| 3     | article:2  | 45        |

### Увеличение просмотров у одной статьи и новый топ-3

К `article:2` добавлено много просмотров через `ZINCRBY`:

```powershell
docker exec redis-redis-1 redis-cli ZINCRBY leaderboard:popular 50000 article:2
# "50045"
```

**Новый топ-3 с просмотрами:**

```powershell
docker exec redis-redis-1 redis-cli ZRANGE leaderboard:popular 0 2 REV WITHSCORES
```

| Место | Статья     | Просмотры |
|-------|------------|-----------|
| 1     | article:2  | 50045     |
| 2     | article:3  | 300       |
| 3     | article:1  | 120       |

---

## Часть 4. Ограничение действий (счётчик + TTL)

Модель из задания: пользователь не более 5 лайков в минуту.  
Ключ: `user:{id}:likes` — в примере `user:7:likes`.

Логика демонстрации в Redis:

- `INCR` увеличивает счётчик лайков в окне;
- `EXPIRE key 60` задаёт TTL 60 секунд — по истечении минуты ключ удалится, счётчик «обнулится» для нового окна (упрощённый вариант rate limiting).

### Команды и вывод

```powershell
docker exec redis-redis-1 redis-cli DEL user:7:likes
# (integer) 1  — при повторном запуске может быть 0 или 1

docker exec redis-redis-1 redis-cli INCR user:7:likes
docker exec redis-redis-1 redis-cli INCR user:7:likes
docker exec redis-redis-1 redis-cli INCR user:7:likes
docker exec redis-redis-1 redis-cli INCR user:7:likes
docker exec redis-redis-1 redis-cli INCR user:7:likes
# ответы: 1, 2, 3, 4, 5

docker exec redis-redis-1 redis-cli EXPIRE user:7:likes 60
# (integer) 1

docker exec redis-redis-1 redis-cli GET user:7:likes
# "5"

docker exec redis-redis-1 redis-cli TTL user:7:likes
# (integer) 59  — оставшееся время жизни в секундах (чуть меньше 60, т.к. между командами прошло время)
```

**Проверки из задания:**

- текущее значение: **5**;
- оставшееся время до удаления ключа: **~59 секунд** (`TTL`; `-1` значит TTL не задан, `-2` — ключа нет).
