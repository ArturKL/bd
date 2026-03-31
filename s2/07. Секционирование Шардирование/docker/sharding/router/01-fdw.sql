-- Router: HASH(2) по id, каждая партиция — внешняя таблица на своём шарде (postgres_fdw).

CREATE EXTENSION postgres_fdw;

CREATE SERVER shard1
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'postgres-shard1',
        dbname 'shard_db',
        port '5432'
    );

CREATE SERVER shard2
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'postgres-shard2',
        dbname 'shard_db',
        port '5432'
    );

CREATE USER MAPPING FOR admin
    SERVER shard1
    OPTIONS (user 'admin', password 'adminpass');

CREATE USER MAPPING FOR admin
    SERVER shard2
    OPTIONS (user 'admin', password 'adminpass');

-- Родитель как в V1 по колонкам и HASH(id), две партиции (MODULUS 2).
-- На coordinator нельзя задать PRIMARY KEY/UNIQUE на всём родителе, если партиции — postgres_fdw
-- (ошибка: «contains indexes that are unique»). Уникальность id обеспечивается на каждом шарде.
-- Без FK unit_id -> unit: справочник unit только на шардах.
CREATE TABLE "user" (
    id BIGINT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    unit_id BIGINT,
    student_number VARCHAR(50),
    employee_position VARCHAR(100),
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_login_at TIMESTAMPTZ
) PARTITION BY HASH (id);

-- remainder 0 → шард 1, remainder 1 → шард 2.
CREATE FOREIGN TABLE user_p0 PARTITION OF "user"
    FOR VALUES WITH (MODULUS 2, REMAINDER 0)
    SERVER shard1
    OPTIONS (schema_name 'public', table_name 'user');

CREATE FOREIGN TABLE user_p1 PARTITION OF "user"
    FOR VALUES WITH (MODULUS 2, REMAINDER 1)
    SERVER shard2
    OPTIONS (schema_name 'public', table_name 'user');
