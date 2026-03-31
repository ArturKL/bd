-- Публикация для логической репликации (выполняется только на primary / publisher).
-- На подписчике миграции Flyway намеренно останавливаются на V4 (см. docker-compose: flyway-logical -target=4).
CREATE PUBLICATION course_pub FOR ALL TABLES WITH (publish_via_partition_root = true);
