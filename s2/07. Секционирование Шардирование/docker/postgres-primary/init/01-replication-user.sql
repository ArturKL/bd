-- Пользователь для физической репликации (pg_basebackup / поток WAL).
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicatorpass';
