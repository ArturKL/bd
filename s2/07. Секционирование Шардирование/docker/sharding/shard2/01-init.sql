-- Та же схема, что на шардe 1 (см. V1__init_tables.sql).
CREATE TABLE unit (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    code VARCHAR(50) UNIQUE,
    parent_id BIGINT REFERENCES unit (id),
    email VARCHAR(255),
    phone VARCHAR(20),
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO unit (name, type, status)
VALUES ('Lab Unit', 'faculty', 'active');

CREATE TABLE "user" (
    id BIGINT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    unit_id BIGINT REFERENCES unit (id),
    student_number VARCHAR(50),
    employee_position VARCHAR(100),
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_login_at TIMESTAMPTZ
);

ANALYZE unit;
ANALYZE "user";
