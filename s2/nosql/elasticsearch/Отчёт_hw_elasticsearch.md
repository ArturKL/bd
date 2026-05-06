## 1. Запуск Elasticsearch

```powershell
cd c:\Users\artur\DataGripProjects\bd\s2\nosql\elasticsearch
docker compose up -d
```

Проверка API (первые ~30–40 с узел может подниматься):

```powershell
curl.exe -s http://localhost:9200

{
  "name" : "e38c8aaf46c6",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "HDNzYX8bRvOxs4Q5yjVHRQ",
  "version" : {
    "number" : "7.17.22",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "38e9ca2e81304a821c50862dafab089ca863944b",
    "build_date" : "2024-06-06T07:35:17.876121680Z",
    "build_snapshot" : false,
    "lucene_version" : "8.11.3",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

---

## 2. Создание индекса `products`

Файл **`mapping-products.json`** задаёт поля:

| Поле       | Тип в индексе | Примечание |
|-----------|---------------|------------|
| `name`    | `text` + подполе `keyword` | полнотекст и точные совпадения по подполю |
| `price`   | `float` | для **range** |
| `category`| `keyword` | для **term** |
| `stock`   | `integer` | доп. поле |

Команда:

```powershell
curl.exe -s -X PUT "http://localhost:9200/products" -H "Content-Type: application/json" --data-binary "@mapping-products.json"

{"acknowledged":true}

{"acknowledged":true,"shards_acknowledged":true,"index":"products"}
```

---

## 3. Наполнение и операции с документами (PUT / POST)

Тела запросов лежат в **`docs/*.json`**

### 3.1 Создать документ (POST, id автоматически)

```powershell
curl.exe -s -X POST "http://localhost:9200/products/_doc" `
  -H "Content-Type: application/json" `
  --data-binary "@docs/post-noid.json"

{"_index":"products","_type":"_doc","_id":"ja-9-p0BKVr-noEeVC_G","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":0,"_primary_term":1}
```


### 3.2 Добавить документ с указанным id (PUT)

```powershell
curl.exe -s -X PUT "http://localhost:9200/products/_doc/1" `
  -H "Content-Type: application/json" `
  --data-binary "@docs/put-1.json"

{"_index":"products","_type":"_doc","_id":"1","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":1,"_primary_term":1}
```

Аналогично загружены документы с **`_id` 2, 3, 4** (`put-2.json` … `put-4.json`).

### 3.3 Обновить документ (POST `/_update/{id}`)

```powershell
curl.exe -s -X POST "http://localhost:9200/products/_update/1" `
  -H "Content-Type: application/json" `
  --data-binary "@docs/update-1.json"

{"_index":"products","_type":"_doc","_id":"1","_version":2,"result":"updated","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":5,"_primary_term":1}
```

В **`update-1.json`** частичное обновление полей `price` и `stock`.


### 3.4 Удалить документ

```powershell
curl.exe -s -X DELETE "http://localhost:9200/products/_doc/4"

{"_index":"products","_type":"_doc","_id":"4","_version":2,"result":"deleted","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":6,"_primary_term":1}
```

### 3.5 Обновить индекс перед поиском

```powershell
curl.exe -s -X POST "http://localhost:9200/products/_refresh"

{"_shards":{"total":2,"successful":1,"failed":0}}
```

---

## 4. Запросы

Все тела запросов лежат в **`queries/*.json`**. Поиск выполняется по **`POST /products/_search`**.

### 4.1 Поиск по названию товара

Поиск по полю **`name`**

```powershell
curl.exe -s "http://localhost:9200/products/_search?pretty" --get --data-urlencode "q=name:ProBook"

{
  "took" : 49,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 1,
      "relation" : "eq"
    },
    "max_score" : 1.0522763,
    "hits" : [
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "1",
        "_score" : 1.0522763,
        "_source" : {
          "name" : "Ноутбук ProBook 15",
          "price" : 84990,
          "category" : "electronics",
          "stock" : 5
        }
      }
    ]
  }
}
```

### 4.2 Запрос `match` (полнотекст)

Файл **`queries/q-match.json`** — `match` по полю `name` с текстом «USB кабель».

```powershell
curl.exe -s -X POST "http://localhost:9200/products/_search?pretty" `
  -H "Content-Type: application/json" `
  --data-binary "@queries/q-match.json"

{
  "took" : 9,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 1,
      "relation" : "eq"
    },
    "max_score" : 2.7814517,
    "hits" : [
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "2",
        "_score" : 2.7814517,
        "_source" : {
          "name" : "USB кабель Type-C",
          "price" : 450,
          "category" : "accessories",
          "stock" : 50
        }
      }
    ]
  }
}
```

### 4.3 Запрос `term`

**`queries/q-term.json`** — точное совпадение `category: electronics` (тип **`keyword`**).

```powershell
{
  "took" : 3,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 2,
      "relation" : "eq"
    },
    "max_score" : 0.6931471,
    "hits" : [
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "3",
        "_score" : 0.6931471,
        "_source" : {
          "name" : "Мышь беспроводная",
          "price" : 2990,
          "category" : "electronics",
          "stock" : 12
        }
      },
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "1",
        "_score" : 0.6931471,
        "_source" : {
          "name" : "Ноутбук ProBook 15",
          "price" : 84990,
          "category" : "electronics",
          "stock" : 5
        }
      }
    ]
  }
}
```

### 4.4 Запрос `range`

**`queries/q-range.json`** — `price` в диапазоне **[100, 50000]**, сортировка по цене.

```powershell
{
  "took" : 11,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 3,
      "relation" : "eq"
    },
    "max_score" : null,
    "hits" : [
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "ja-9-p0BKVr-noEeVC_G",
        "_score" : null,
        "_source" : {
          "name" : "Постер без явного id",
          "price" : 300,
          "category" : "decor",
          "stock" : 2
        },
        "sort" : [
          300.0
        ]
      },
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "2",
        "_score" : null,
        "_source" : {
          "name" : "USB кабель Type-C",
          "price" : 450,
          "category" : "accessories",
          "stock" : 50
        },
        "sort" : [
          450.0
        ]
      },
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "3",
        "_score" : null,
        "_source" : {
          "name" : "Мышь беспроводная",
          "price" : 2990,
          "category" : "electronics",
          "stock" : 12
        },
        "sort" : [
          2990.0
        ]
      }
    ]
  }
}

```

### 4.5 Запрос `bool`

**`queries/q-bool.json`**:

- **`must`**: `match` по `name` со словом «USB»;
- **`filter`**: `term` по `category` = `accessories` и **`range`** `price <= 1000`.

```powershell
{
  "took" : 3,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 1,
      "relation" : "eq"
    },
    "max_score" : 1.3907259,
    "hits" : [
      {
        "_index" : "products",
        "_type" : "_doc",
        "_id" : "2",
        "_score" : 1.3907259,
        "_source" : {
          "name" : "USB кабель Type-C",
          "price" : 450,
          "category" : "accessories",
          "stock" : 50
        }
      }
    ]
  }
}
```
