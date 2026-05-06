# Elasticsearch

## Запуск

```bash
docker run -p 9200:9200 -e "discovery.type=single-node" elasticsearch:7.17.22
```

В этой же папке есть **`docker-compose.yml`** с тем же образом **`elasticsearch:7.17.22`** (single-node, порт **9200**). Запуск: `docker compose up -d`. Подробности выполнения ДЗ — в **`Отчёт_hw_elasticsearch.md`**.