--    1НФ 
-- 1 правка 
ALTER TABLE lesson DROP CONSTRAINT IF EXISTS lesson_auditorium_id_fkey;
ALTER TABLE exam DROP CONSTRAINT IF EXISTS exam_auditorium_id_fkey;

CREATE TABLE lesson_classroom (
    lesson_id BIGINT NOT NULL REFERENCES lesson(id) ON DELETE CASCADE,
    classroom_id BIGINT NOT NULL REFERENCES classroom(id) ON DELETE CASCADE,
    PRIMARY KEY (lesson_id, classroom_id)
);

CREATE TABLE exam_classroom (
    exam_id BIGINT NOT NULL REFERENCES exam(id) ON DELETE CASCADE,
    classroom_id BIGINT NOT NULL REFERENCES classroom(id) ON DELETE CASCADE,
    PRIMARY KEY (exam_id, classroom_id)
);

ALTER TABLE lesson DROP COLUMN auditorium_id;
ALTER TABLE exam DROP COLUMN auditorium_id;

-- 2 правка
ALTER TABLE "user" DROP CONSTRAINT IF EXISTS user_role_id_fkey;

CREATE TABLE user_role (
    user_id BIGINT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

ALTER TABLE "user" DROP COLUMN role_id;


--     3НФ 
-- 1 правка
ALTER TABLE "user" DROP COLUMN middle_name;

-- 2 правка
CREATE TABLE discipline_teacher (
    discipline_id BIGINT NOT NULL REFERENCES discipline(id) ON DELETE CASCADE,
    teacher_id BIGINT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    PRIMARY KEY (discipline_id, teacher_id)
);
ALTER TABLE enrollment DROP COLUMN role;

-- 3 правка
ALTER TABLE classroom DROP COLUMN campus;


-- Доп правки
ALTER TABLE discipline DROP CONSTRAINT IF EXISTS discipline_unit_id_fkey;
ALTER TABLE discipline DROP COLUMN IF EXISTS unit_id;
ALTER TABLE discipline ADD COLUMN flow_id BIGINT REFERENCES flow(id) ON DELETE SET NULL;

ALTER TABLE assignment DROP CONSTRAINT IF EXISTS assignment_flow_id_fkey;
ALTER TABLE assignment ADD COLUMN discipline_id BIGINT REFERENCES discipline(id) ON DELETE CASCADE;
ALTER TABLE assignment DROP COLUMN flow_id;
