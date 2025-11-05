-- ============================================
-- ЗАПОЛНЕНИЕ БАЗЫ ДАННЫХ ТЕСТОВЫМИ ДАННЫМИ
-- ============================================
-- Этот файл заполняет БД небольшим количеством тестовых данных
-- 
-- ИСПОЛЬЗОВАНИЕ В PGADMIN:
-- 
-- 1. Убедитесь, что база данных university создана и таблицы созданы (init_tables.sql)
-- 2. Подключитесь к базе university
-- 3. Откройте Query Tool
-- 4. Выполните этот файл (F5 или Execute)

-- ============================================
-- ОЧИСТКА ВСЕХ ТАБЛИЦ (в порядке зависимостей)
-- ============================================

TRUNCATE TABLE lecturer_phone CASCADE;
TRUNCATE TABLE exam_classroom CASCADE;
TRUNCATE TABLE lesson_classroom CASCADE;
TRUNCATE TABLE discipline_teacher CASCADE;
TRUNCATE TABLE user_role CASCADE;
TRUNCATE TABLE exam CASCADE;
TRUNCATE TABLE assignment CASCADE;
TRUNCATE TABLE enrollment CASCADE;
TRUNCATE TABLE lesson CASCADE;
TRUNCATE TABLE discipline CASCADE;
TRUNCATE TABLE flow CASCADE;
TRUNCATE TABLE "user" CASCADE;
TRUNCATE TABLE classroom CASCADE;
TRUNCATE TABLE unit CASCADE;
TRUNCATE TABLE assignment_status CASCADE;
TRUNCATE TABLE exam_status CASCADE;
TRUNCATE TABLE role CASCADE;

-- ============================================
-- 1. РОЛИ
-- ============================================

INSERT INTO role (code, name, description, is_system, status) VALUES
('student', 'Студент', 'Роль студента', FALSE, 'active'),
('teacher', 'Преподаватель', 'Роль преподавателя', FALSE, 'active'),
('admin', 'Администратор', 'Роль администратора системы', TRUE, 'active');

-- ============================================
-- 2. ПОДРАЗДЕЛЕНИЯ (сначала родительские)
-- ============================================

-- Вставляем родительские подразделения
INSERT INTO unit (name, type, code, parent_id, email, phone, status) VALUES
('Институт математики и информатики', 'faculty', 'IMI', NULL, 'imi@university.edu', '+7-495-123-45-67', 'active'),
('Институт гуманитарных наук', 'faculty', 'IGH', NULL, 'igh@university.edu', '+7-495-123-45-68', 'active');

-- Теперь дочерние подразделения (используем подзапросы для получения ID родительских)
INSERT INTO unit (name, type, code, parent_id, email, phone, status) VALUES
('Кафедра математического анализа', 'department', 'MATH', 
    (SELECT id FROM unit WHERE code = 'IMI'), 
    'math@university.edu', '+7-495-123-45-70', 'active'),
('Кафедра информатики', 'department', 'CS', 
    (SELECT id FROM unit WHERE code = 'IMI'), 
    'cs@university.edu', '+7-495-123-45-71', 'active'),
('Кафедра истории', 'department', 'HIST', 
    (SELECT id FROM unit WHERE code = 'IGH'), 
    'hist@university.edu', '+7-495-123-45-72', 'active');

-- ============================================
-- 3. ПОЛЬЗОВАТЕЛИ
-- ============================================

INSERT INTO "user" (full_name, email, phone, unit_id, student_number, employee_position, status, last_login_at) VALUES
-- Студенты
('Иванов Иван Иванович', 'ivanov@student.university.edu', '+7-999-111-22-33', 
    (SELECT id FROM unit WHERE code = 'IMI'), 'ST-2023-001', NULL, 'active', '2025-01-15 10:30:00+03'),
('Петрова Мария Сергеевна', 'petrova@student.university.edu', '+7-999-111-22-34', 
    (SELECT id FROM unit WHERE code = 'IMI'), 'ST-2023-002', NULL, 'active', '2025-01-15 11:20:00+03'),
('Сидоров Алексей Дмитриевич', 'sidorov@student.university.edu', '+7-999-111-22-35', 
    (SELECT id FROM unit WHERE code = 'IMI'), 'ST-2023-003', NULL, 'active', '2025-01-14 09:15:00+03'),
('Козлова Анна Владимировна', 'kozlova@student.university.edu', '+7-999-111-22-36', 
    (SELECT id FROM unit WHERE code = 'IGH'), 'ST-2023-004', NULL, 'active', '2025-01-15 14:45:00+03'),
-- Преподаватели
('Смирнов Петр Николаевич', 'smirnov@teacher.university.edu', '+7-999-222-33-44', 
    (SELECT id FROM unit WHERE code = 'MATH'), NULL, 'Профессор', 'active', '2025-01-15 08:00:00+03'),
('Волкова Елена Александровна', 'volkova@teacher.university.edu', '+7-999-222-33-45', 
    (SELECT id FROM unit WHERE code = 'CS'), NULL, 'Доцент', 'active', '2025-01-15 09:30:00+03'),
('Морозов Дмитрий Сергеевич', 'morozov@teacher.university.edu', '+7-999-222-33-46', 
    (SELECT id FROM unit WHERE code = 'CS'), NULL, 'Старший преподаватель', 'active', '2025-01-14 16:20:00+03'),
('Новикова Ольга Ивановна', 'novikova@teacher.university.edu', '+7-999-222-33-47', 
    (SELECT id FROM unit WHERE code = 'HIST'), NULL, 'Доцент', 'active', '2025-01-13 12:10:00+03');

-- ============================================
-- 4. ПОТОКИ
-- ============================================

INSERT INTO flow (code, title, unit_id, owner_id, credits, cohort_year, modality, language, start_date, end_date, add_drop_deadline, exam_window_start, exam_window_end, grade_submit_deadline, max_students, status) VALUES
('MATH101-F23', 'Математический анализ, поток 2023', 
    (SELECT id FROM unit WHERE code = 'MATH'), 
    (SELECT id FROM "user" WHERE email = 'smirnov@teacher.university.edu'), 
    6.0, 2023, 'on-campus', 'ru', '2023-09-01', '2024-01-31', '2023-09-15', '2024-01-15', '2024-01-31', '2024-02-10', 30, 'active'),
('CS201-F23', 'Программирование на C#, поток 2023', 
    (SELECT id FROM unit WHERE code = 'CS'), 
    (SELECT id FROM "user" WHERE email = 'volkova@teacher.university.edu'), 
    4.0, 2023, 'on-campus', 'ru', '2023-09-01', '2024-01-31', '2023-09-15', '2024-01-15', '2024-01-31', '2024-02-10', 25, 'active'),
('HIST101-F23', 'История России, поток 2023', 
    (SELECT id FROM unit WHERE code = 'HIST'), 
    (SELECT id FROM "user" WHERE email = 'novikova@teacher.university.edu'), 
    3.0, 2023, 'hybrid', 'ru', '2023-09-01', '2024-01-31', '2023-09-15', '2024-01-15', '2024-01-31', '2024-02-10', 40, 'active');

-- ============================================
-- 5. ДИСЦИПЛИНЫ
-- ============================================

INSERT INTO discipline (code, title, description, ects_credits, flow_id, lecturer_id, level, language, status) VALUES
('MATH101', 'Математический анализ', 'Курс математического анализа для первого курса', 6.0, 
    (SELECT id FROM flow WHERE code = 'MATH101-F23'), 
    (SELECT id FROM "user" WHERE email = 'smirnov@teacher.university.edu'), 'bachelor', 'ru', 'active'),
('CS201', 'Программирование на C#', 'Основы программирования на языке C#', 4.0, 
    (SELECT id FROM flow WHERE code = 'CS201-F23'), 
    (SELECT id FROM "user" WHERE email = 'volkova@teacher.university.edu'), 'bachelor', 'ru', 'active'),
('CS202', 'Базы данных', 'Основы проектирования и работы с базами данных', 5.0, 
    (SELECT id FROM flow WHERE code = 'CS201-F23'), 
    (SELECT id FROM "user" WHERE email = 'morozov@teacher.university.edu'), 'bachelor', 'ru', 'active'),
('HIST101', 'История России', 'Курс истории России с древнейших времен до наших дней', 3.0, 
    (SELECT id FROM flow WHERE code = 'HIST101-F23'), 
    (SELECT id FROM "user" WHERE email = 'novikova@teacher.university.edu'), 'bachelor', 'ru', 'active');

-- ============================================
-- 6. АУДИТОРИИ
-- ============================================

INSERT INTO classroom (building, room_number, capacity, floor, has_projector, has_pc, is_accessible, status) VALUES
('Главный корпус', '101', 30, 1, TRUE, TRUE, TRUE, 'active'),
('Главный корпус', '205', 25, 2, TRUE, FALSE, TRUE, 'active'),
('Главный корпус', '310', 40, 3, TRUE, TRUE, TRUE, 'active'),
('Корпус Б', '102', 20, 1, FALSE, FALSE, TRUE, 'active'),
('Корпус Б', '201', 35, 2, TRUE, TRUE, FALSE, 'active');

-- ============================================
-- 7. СПРАВОЧНИКИ СТАТУСОВ
-- ============================================

INSERT INTO exam_status (name) VALUES
('planned'),
('in_progress'),
('completed'),
('canceled');

INSERT INTO assignment_status (name) VALUES
('draft'),
('published'),
('closed'),
('graded');

-- ============================================
-- 8. ЗАДАНИЯ
-- ============================================

INSERT INTO assignment (discipline_id, title, type, description, release_at, due_at, late_policy, submission_type, allow_multiple, max_attempts, max_score, visibility, status, status_id) VALUES
((SELECT id FROM discipline WHERE code = 'MATH101'), 'Домашнее задание 1: Пределы', 'homework', 'Решить задачи на вычисление пределов', '2023-09-10 00:00:00+03', '2023-09-24 23:59:59+03', 'strict', 'file', FALSE, 1, 10.0, 'visible', 'published', (SELECT id FROM assignment_status WHERE name = 'published')),
((SELECT id FROM discipline WHERE code = 'MATH101'), 'Контрольная работа 1', 'exam', 'Контрольная работа по теме "Производные"', '2023-10-01 00:00:00+03', '2023-10-08 23:59:59+03', 'strict', 'file', FALSE, 1, 20.0, 'visible', 'published', (SELECT id FROM assignment_status WHERE name = 'published')),
((SELECT id FROM discipline WHERE code = 'CS201'), 'Лабораторная работа 1: Основы C#', 'lab', 'Создать консольное приложение', '2023-09-05 00:00:00+03', '2023-09-19 23:59:59+03', 'penalty', 'file', TRUE, 3, 15.0, 'visible', 'published', (SELECT id FROM assignment_status WHERE name = 'published')),
((SELECT id FROM discipline WHERE code = 'CS201'), 'Проект: Калькулятор', 'project', 'Разработать калькулятор с GUI', '2023-10-01 00:00:00+03', '2023-11-15 23:59:59+03', 'penalty', 'file', FALSE, 1, 30.0, 'visible', 'published', (SELECT id FROM assignment_status WHERE name = 'published')),
((SELECT id FROM discipline WHERE code = 'CS202'), 'Домашнее задание: SQL запросы', 'homework', 'Написать SQL запросы для заданной БД', '2023-09-15 00:00:00+03', '2023-09-29 23:59:59+03', 'penalty', 'file', TRUE, 2, 12.0, 'visible', 'published', (SELECT id FROM assignment_status WHERE name = 'published')),
((SELECT id FROM discipline WHERE code = 'HIST101'), 'Реферат: Реформы Петра I', 'essay', 'Написать реферат на заданную тему', '2023-09-10 00:00:00+03', '2023-10-10 23:59:59+03', 'penalty', 'file', FALSE, 1, 25.0, 'visible', 'published', (SELECT id FROM assignment_status WHERE name = 'published'));

-- ============================================
-- 9. ЗАЧИСЛЕНИЯ
-- ============================================

INSERT INTO enrollment (user_id, discipline_id, flow_id, enrolled_at, attendance_pct, current_score, final_grade, status) VALUES
((SELECT id FROM "user" WHERE email = 'ivanov@student.university.edu'), 
    (SELECT id FROM discipline WHERE code = 'MATH101'), 
    (SELECT id FROM flow WHERE code = 'MATH101-F23'), 
    '2023-09-01 10:00:00+03', 95.5, 87.5, NULL, 'active'),
((SELECT id FROM "user" WHERE email = 'petrova@student.university.edu'), 
    (SELECT id FROM discipline WHERE code = 'MATH101'), 
    (SELECT id FROM flow WHERE code = 'MATH101-F23'), 
    '2023-09-01 10:05:00+03', 92.0, 91.0, NULL, 'active'),
((SELECT id FROM "user" WHERE email = 'sidorov@student.university.edu'), 
    (SELECT id FROM discipline WHERE code = 'CS201'), 
    (SELECT id FROM flow WHERE code = 'CS201-F23'), 
    '2023-09-01 11:00:00+03', 88.5, 78.0, NULL, 'active'),
((SELECT id FROM "user" WHERE email = 'ivanov@student.university.edu'), 
    (SELECT id FROM discipline WHERE code = 'CS201'), 
    (SELECT id FROM flow WHERE code = 'CS201-F23'), 
    '2023-09-01 11:05:00+03', 90.0, 85.0, NULL, 'active'),
((SELECT id FROM "user" WHERE email = 'petrova@student.university.edu'), 
    (SELECT id FROM discipline WHERE code = 'CS201'), 
    (SELECT id FROM flow WHERE code = 'CS201-F23'), 
    '2023-09-01 11:10:00+03', 85.0, 82.5, NULL, 'active'),
((SELECT id FROM "user" WHERE email = 'kozlova@student.university.edu'), 
    (SELECT id FROM discipline WHERE code = 'CS202'), 
    (SELECT id FROM flow WHERE code = 'CS201-F23'), 
    '2023-09-01 11:15:00+03', 93.0, 88.0, NULL, 'active'),
((SELECT id FROM "user" WHERE email = 'kozlova@student.university.edu'), 
    (SELECT id FROM discipline WHERE code = 'HIST101'), 
    (SELECT id FROM flow WHERE code = 'HIST101-F23'), 
    '2023-09-01 12:00:00+03', 98.0, 94.5, NULL, 'active');

-- ============================================
-- 10. ЭКЗАМЕНЫ
-- ============================================

INSERT INTO exam (discipline_id, type, scheduled_start, scheduled_end, format, duration_min, max_score, proctor_id, status, status_id) VALUES
((SELECT id FROM discipline WHERE code = 'MATH101'), 'final', '2024-01-20 09:00:00+03', '2024-01-20 12:00:00+03', 'written', 180, 100.0, 
    (SELECT id FROM "user" WHERE email = 'smirnov@teacher.university.edu'), 'planned', (SELECT id FROM exam_status WHERE name = 'planned')),
((SELECT id FROM discipline WHERE code = 'CS201'), 'midterm', '2023-10-15 10:00:00+03', '2023-10-15 11:30:00+03', 'test', 90, 50.0, 
    (SELECT id FROM "user" WHERE email = 'volkova@teacher.university.edu'), 'completed', (SELECT id FROM exam_status WHERE name = 'completed')),
((SELECT id FROM discipline WHERE code = 'CS202'), 'final', '2024-01-25 14:00:00+03', '2024-01-25 17:00:00+03', 'written', 180, 100.0, 
    (SELECT id FROM "user" WHERE email = 'morozov@teacher.university.edu'), 'planned', (SELECT id FROM exam_status WHERE name = 'planned')),
((SELECT id FROM discipline WHERE code = 'HIST101'), 'final', '2024-01-22 10:00:00+03', '2024-01-22 12:00:00+03', 'oral', 120, 50.0, 
    (SELECT id FROM "user" WHERE email = 'novikova@teacher.university.edu'), 'planned', (SELECT id FROM exam_status WHERE name = 'planned'));

-- ============================================
-- 11. ЗАНЯТИЯ
-- ============================================

INSERT INTO lesson (flow_id, type, topic, start_at, end_at, teacher_id, online_link, attendance_required, status) VALUES
((SELECT id FROM flow WHERE code = 'MATH101-F23'), 'lecture', 'Введение в математический анализ. Пределы', '2023-09-05 09:00:00+03', '2023-09-05 10:30:00+03', 
    (SELECT id FROM "user" WHERE email = 'smirnov@teacher.university.edu'), NULL, TRUE, 'completed'),
((SELECT id FROM flow WHERE code = 'MATH101-F23'), 'seminar', 'Решение задач на пределы', '2023-09-07 09:00:00+03', '2023-09-07 10:30:00+03', 
    (SELECT id FROM "user" WHERE email = 'smirnov@teacher.university.edu'), NULL, TRUE, 'completed'),
((SELECT id FROM flow WHERE code = 'MATH101-F23'), 'lecture', 'Производные функции', '2023-09-12 09:00:00+03', '2023-09-12 10:30:00+03', 
    (SELECT id FROM "user" WHERE email = 'smirnov@teacher.university.edu'), NULL, TRUE, 'completed'),
((SELECT id FROM flow WHERE code = 'CS201-F23'), 'lecture', 'Введение в C#. Основы синтаксиса', '2023-09-04 14:00:00+03', '2023-09-04 15:30:00+03', 
    (SELECT id FROM "user" WHERE email = 'volkova@teacher.university.edu'), NULL, TRUE, 'completed'),
((SELECT id FROM flow WHERE code = 'CS201-F23'), 'lab', 'Практическая работа: Переменные и типы данных', '2023-09-06 14:00:00+03', '2023-09-06 16:00:00+03', 
    (SELECT id FROM "user" WHERE email = 'volkova@teacher.university.edu'), NULL, TRUE, 'completed'),
((SELECT id FROM flow WHERE code = 'CS201-F23'), 'lecture', 'ООП в C#', '2023-09-11 14:00:00+03', '2023-09-11 15:30:00+03', 
    (SELECT id FROM "user" WHERE email = 'morozov@teacher.university.edu'), NULL, TRUE, 'completed'),
((SELECT id FROM flow WHERE code = 'HIST101-F23'), 'lecture', 'Древняя Русь', '2023-09-05 11:00:00+03', '2023-09-05 12:30:00+03', 
    (SELECT id FROM "user" WHERE email = 'novikova@teacher.university.edu'), NULL, TRUE, 'completed'),
((SELECT id FROM flow WHERE code = 'HIST101-F23'), 'seminar', 'Обсуждение эпохи Петра I', '2023-09-07 11:00:00+03', '2023-09-07 12:30:00+03', 
    (SELECT id FROM "user" WHERE email = 'novikova@teacher.university.edu'), NULL, TRUE, 'completed');

-- ============================================
-- 12. СВЯЗУЮЩИЕ ТАБЛИЦЫ
-- ============================================

-- Связь пользователей и ролей
INSERT INTO user_role (user_id, role_id) VALUES
((SELECT id FROM "user" WHERE email = 'ivanov@student.university.edu'), (SELECT id FROM role WHERE code = 'student')),
((SELECT id FROM "user" WHERE email = 'petrova@student.university.edu'), (SELECT id FROM role WHERE code = 'student')),
((SELECT id FROM "user" WHERE email = 'sidorov@student.university.edu'), (SELECT id FROM role WHERE code = 'student')),
((SELECT id FROM "user" WHERE email = 'kozlova@student.university.edu'), (SELECT id FROM role WHERE code = 'student')),
((SELECT id FROM "user" WHERE email = 'smirnov@teacher.university.edu'), (SELECT id FROM role WHERE code = 'teacher')),
((SELECT id FROM "user" WHERE email = 'volkova@teacher.university.edu'), (SELECT id FROM role WHERE code = 'teacher')),
((SELECT id FROM "user" WHERE email = 'morozov@teacher.university.edu'), (SELECT id FROM role WHERE code = 'teacher')),
((SELECT id FROM "user" WHERE email = 'novikova@teacher.university.edu'), (SELECT id FROM role WHERE code = 'teacher'));

-- Связь дисциплин и преподавателей
INSERT INTO discipline_teacher (discipline_id, teacher_id) VALUES
((SELECT id FROM discipline WHERE code = 'MATH101'), (SELECT id FROM "user" WHERE email = 'smirnov@teacher.university.edu')),
((SELECT id FROM discipline WHERE code = 'CS201'), (SELECT id FROM "user" WHERE email = 'volkova@teacher.university.edu')),
((SELECT id FROM discipline WHERE code = 'CS202'), (SELECT id FROM "user" WHERE email = 'morozov@teacher.university.edu')),
((SELECT id FROM discipline WHERE code = 'HIST101'), (SELECT id FROM "user" WHERE email = 'novikova@teacher.university.edu'));

-- Связь занятий и аудиторий
INSERT INTO lesson_classroom (lesson_id, classroom_id)
SELECT l.id, (SELECT id FROM classroom WHERE building = 'Главный корпус' AND room_number = '101')
FROM lesson l
WHERE l.flow_id = (SELECT id FROM flow WHERE code = 'MATH101-F23')
LIMIT 3;

INSERT INTO lesson_classroom (lesson_id, classroom_id)
SELECT l.id, (SELECT id FROM classroom WHERE building = 'Главный корпус' AND room_number = '205')
FROM lesson l
WHERE l.flow_id = (SELECT id FROM flow WHERE code = 'CS201-F23')
LIMIT 3;

INSERT INTO lesson_classroom (lesson_id, classroom_id)
SELECT l.id, (SELECT id FROM classroom WHERE building = 'Главный корпус' AND room_number = '310')
FROM lesson l
WHERE l.flow_id = (SELECT id FROM flow WHERE code = 'HIST101-F23')
LIMIT 2;

-- Связь экзаменов и аудиторий
INSERT INTO exam_classroom (exam_id, classroom_id) VALUES
((SELECT id FROM exam WHERE discipline_id = (SELECT id FROM discipline WHERE code = 'MATH101')), 
    (SELECT id FROM classroom WHERE building = 'Главный корпус' AND room_number = '101')),
((SELECT id FROM exam WHERE discipline_id = (SELECT id FROM discipline WHERE code = 'CS201')), 
    (SELECT id FROM classroom WHERE building = 'Главный корпус' AND room_number = '205')),
((SELECT id FROM exam WHERE discipline_id = (SELECT id FROM discipline WHERE code = 'CS202')), 
    (SELECT id FROM classroom WHERE building = 'Главный корпус' AND room_number = '205')),
((SELECT id FROM exam WHERE discipline_id = (SELECT id FROM discipline WHERE code = 'HIST101')), 
    (SELECT id FROM classroom WHERE building = 'Главный корпус' AND room_number = '310'));

-- Телефоны преподавателей
INSERT INTO lecturer_phone (lecturer_id, phone_number) VALUES
((SELECT id FROM "user" WHERE email = 'smirnov@teacher.university.edu'), '+7-999-222-33-44'),
((SELECT id FROM "user" WHERE email = 'smirnov@teacher.university.edu'), '+7-495-123-45-70'),
((SELECT id FROM "user" WHERE email = 'volkova@teacher.university.edu'), '+7-999-222-33-45'),
((SELECT id FROM "user" WHERE email = 'morozov@teacher.university.edu'), '+7-999-222-33-46'),
((SELECT id FROM "user" WHERE email = 'novikova@teacher.university.edu'), '+7-999-222-33-47');

-- ============================================
-- КОНЕЦ ЗАПОЛНЕНИЯ ДАННЫМИ
-- ============================================

