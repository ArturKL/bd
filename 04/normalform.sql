-- =========================
-- === 1НФ =================
-- =========================

-- 1) Несколько аудиторий в экзамене/уроке
ALTER TABLE lesson DROP CONSTRAINT IF EXISTS lesson_auditorium_id_fkey;
ALTER TABLE exam DROP CONSTRAINT IF EXISTS exam_auditorium_id_fkey;

CREATE TABLE lesson_classroom (
                                  lesson_id    BIGINT NOT NULL REFERENCES lesson(id) ON DELETE CASCADE,
                                  classroom_id BIGINT NOT NULL REFERENCES classroom(id) ON DELETE CASCADE,
                                  PRIMARY KEY (lesson_id, classroom_id)
);

CREATE TABLE exam_classroom (
                                exam_id      BIGINT NOT NULL REFERENCES exam(id) ON DELETE CASCADE,
                                classroom_id BIGINT NOT NULL REFERENCES classroom(id) ON DELETE CASCADE,
                                PRIMARY KEY (exam_id, classroom_id)
);

ALTER TABLE lesson DROP COLUMN auditorium_id;
ALTER TABLE exam DROP COLUMN auditorium_id;

-- 2) Несколько ролей у пользователя
ALTER TABLE "user" DROP CONSTRAINT IF EXISTS user_role_id_fkey;

CREATE TABLE user_role (
                           user_id BIGINT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
                           role_id BIGINT NOT NULL REFERENCES role(id) ON DELETE CASCADE,
                           PRIMARY KEY (user_id, role_id)
);

ALTER TABLE "user" DROP COLUMN role_id;

-- 3) Телефоны преподавателей (если ранее были в одной колонке)
CREATE TABLE lecturer_phone (
                                lecturer_id  BIGINT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
                                phone_number TEXT NOT NULL,
                                PRIMARY KEY (lecturer_id, phone_number)
);

-- =========================
-- === 3НФ =================
-- =========================

-- 1) middle_name дублирует full_name
ALTER TABLE "user" DROP COLUMN IF EXISTS middle_name;

-- 2) Разделение ролей студентов и преподавателей
CREATE TABLE discipline_teacher (
                                    discipline_id BIGINT NOT NULL REFERENCES discipline(id) ON DELETE CASCADE,
                                    teacher_id    BIGINT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
                                    PRIMARY KEY (discipline_id, teacher_id)
);
ALTER TABLE enrollment DROP COLUMN IF EXISTS role;

-- 3) campus дублирует building
ALTER TABLE classroom DROP COLUMN IF EXISTS campus;

-- 4) Справочники статусов
CREATE TABLE exam_status (
                             id SERIAL PRIMARY KEY,
                             name TEXT NOT NULL
);

CREATE TABLE assignment_status (
                                   id SERIAL PRIMARY KEY,
                                   name TEXT NOT NULL
);

-- Добавляем связи
ALTER TABLE exam
    ADD COLUMN status_id INT REFERENCES exam_status(id) ON DELETE SET NULL;

ALTER TABLE assignment
    ADD COLUMN status_id INT REFERENCES assignment_status(id) ON DELETE SET NULL;

-- =========================
-- === ДОПОЛНИТЕЛЬНЫЕ =====
-- =========================

-- 1) discipline.unit_id → flow_id
ALTER TABLE discipline DROP CONSTRAINT IF EXISTS discipline_unit_id_fkey;
ALTER TABLE discipline DROP COLUMN IF EXISTS unit_id;
ALTER TABLE discipline ADD COLUMN flow_id BIGINT REFERENCES flow(id) ON DELETE SET NULL;

-- 2) assignment.flow_id → discipline_id
ALTER TABLE assignment DROP CONSTRAINT IF EXISTS assignment_flow_id_fkey;
ALTER TABLE assignment ADD COLUMN discipline_id BIGINT REFERENCES discipline(id) ON DELETE CASCADE;
ALTER TABLE assignment DROP COLUMN IF EXISTS flow_id;

-- 3) exam.flow_id → discipline_id
ALTER TABLE exam DROP CONSTRAINT IF EXISTS exam_flow_id_fkey;
ALTER TABLE exam ADD COLUMN discipline_id BIGINT REFERENCES discipline(id) ON DELETE CASCADE;
ALTER TABLE exam DROP COLUMN IF EXISTS flow_id;

-- 4) lecturer в discipline → ссылка на user
ALTER TABLE discipline DROP COLUMN IF EXISTS lecturer;
ALTER TABLE discipline ADD COLUMN lecturer_id BIGINT REFERENCES "user"(id) ON DELETE SET NULL;