INSERT INTO "user" (id, full_name, email, phone, unit_id, student_number, employee_position, status, created_at,
                     updated_at, last_login_at)
VALUES (1, 'Alice', 'alice@lab.local', '+1000001', 1, 'SN-1', NULL, 'active',
        '2026-03-01 10:00:00+00', '2026-03-01 10:00:00+00', NULL),
       (2, 'Bob', 'bob@lab.local', '+1000002', 1, 'SN-2', NULL, 'active',
        '2026-03-02 11:00:00+00', '2026-03-02 11:00:00+00', NULL),
       (3, 'Carol', 'carol@lab.local', NULL, 1, 'SN-3', 'TA', 'active',
        '2026-03-03 12:00:00+00', '2026-03-03 12:00:00+00', '2026-03-10 08:00:00+00'),
       (4, 'Dan', 'dan@lab.local', '+1000004', 1, 'SN-4', NULL, 'inactive',
        '2026-03-04 13:00:00+00', '2026-03-04 13:00:00+00', NULL),
       (5, 'Eve', 'eve@lab.local', NULL, 1, 'SN-5', NULL, 'pending',
        '2026-03-05 14:00:00+00', '2026-03-05 14:00:00+00', NULL);

ANALYZE "user";
