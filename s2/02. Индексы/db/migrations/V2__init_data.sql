-- Clear existing data first if needed
TRUNCATE TABLE enrollment, lesson, flow, "user", unit RESTART IDENTITY CASCADE;

ALTER TABLE flow
    ADD COLUMN tags         TEXT[],
    ADD COLUMN metadata     JSONB,
    ADD COLUMN active_range daterange,
    ADD COLUMN description  TEXT;

ALTER TABLE "user"
    ADD COLUMN bio           TEXT,
    ADD COLUMN interests     TEXT[],
    ADD COLUMN profile       JSONB,
    ADD COLUMN active_period tstzrange,
    ADD COLUMN home_location point;

ALTER TABLE lesson
    ADD COLUMN materials JSONB,
    ADD COLUMN topics    TEXT[],
    ADD COLUMN time_slot tstzrange;

ALTER TABLE enrollment
    ADD COLUMN progress         JSONB,
    ADD COLUMN attendance_range numrange;

-- 100 units
INSERT INTO unit(name, type, status)
SELECT 'Unit ' || i,
       'faculty',
       'active'
FROM generate_series(1, 100) i;


-- 250k users
INSERT INTO "user" (full_name,
                    email,
                    phone,
                    unit_id,
                    student_number,
                    status,
                    bio,
                    interests,
                    profile,
                    active_period,
                    home_location)
SELECT 'N' || i,
       'user' || i || '@mail.com',
       CASE
           WHEN random() < 0.15 THEN NULL
           ELSE '+123' || i
           END,

       -- 70% belong to 10 units (skew)
       CASE
           WHEN random() < 0.7 THEN floor(random() * 10) + 1
           ELSE floor(random() * 90) + 11
           END,

       'SN' || i,

       (ARRAY ['active','inactive','blocked','pending'])
           [floor(random() * 4) + 1],

       'This is user bio number ' || i,

       (ARRAY [
           'math','cs','physics','art','history'
           ])[floor(random() * 5) + 1:floor(random() * 5) + 1],

       jsonb_build_object(
               'rating', floor(random() * 5),
               'verified', random() < 0.3
       ),

       tstzrange(
               now() - (random() * 365) * interval '1 day',
               now()
       ),

       point(random() * 100, random() * 100)
FROM generate_series(1, 250000) i;


-- 250k flows
INSERT INTO flow (code,
                  title,
                  unit_id,
                  credits,
                  cohort_year,
                  modality,
                  start_date,
                  end_date,
                  status,
                  tags,
                  metadata,
                  active_range,
                  description)
SELECT 'FL' || i,
       'Flow ' || i,

       CASE
           WHEN random() < 0.7 THEN floor(random() * 10) + 1
           ELSE floor(random() * 90) + 11
           END,

       round((random() * 5 + 1)::numeric, 1),
       2015 + floor(random() * 10),

       (ARRAY ['online','offline','hybrid'])
           [floor(random() * 3) + 1],

       current_date - floor(random() * 1000)::int,
       current_date + floor(random() * 1000)::int,

       (ARRAY ['active','archived','draft'])
           [floor(random() * 3) + 1],

       ARRAY ['tag1','tag2','tag3'],

       jsonb_build_object(
               'difficulty', floor(random() * 3),
               'has_exam', random() < 0.8
       ),

       daterange(
                       current_date - 100,
                       current_date + 100
       ),

       'Detailed description of flow ' || i

FROM generate_series(1, 250000) i;

-- 250k lessons
INSERT INTO lesson (flow_id,
                    type,
                    topic,
                    start_at,
                    end_at,
                    teacher_id,
                    attendance_required,
                    status,
                    materials,
                    topics,
                    time_slot)
SELECT CASE
           WHEN random() < 0.7 THEN floor(random() * 10000) + 1
           ELSE floor(random() * 240000) + 10001
           END,

       (ARRAY ['lecture','seminar','lab'])
           [floor(random() * 3) + 1],

       'Topic ' || i,

       now() - (random() * 365) * interval '1 day',
       now(),

       floor(random() * 250000) + 1,

       random() < 0.8,

       (ARRAY ['scheduled','done','cancelled'])
           [floor(random() * 3) + 1],

       jsonb_build_object(
               'slides', random() < 0.9,
               'recorded', random() < 0.6
       ),

       ARRAY ['topic1','topic2','topic3'],

       tstzrange(
               now() - interval '2 hours',
               now()
       )
FROM generate_series(1, 250000) i;


-- 250k enrollments
INSERT INTO enrollment (user_id,
                        flow_id,
                        enrolled_at,
                        dropped_at,
                        attendance_pct,
                        current_score,
                        status,
                        progress,
                        attendance_range)
SELECT i,
       floor(random() * 250000) + 1,
       now() - (random() * 200) * interval '1 day',

       CASE
           WHEN random() < 0.1
               THEN now()
           ELSE NULL
           END,

       round((random() * 100)::numeric, 2),
       round((random() * 100)::numeric, 2),

       (ARRAY ['active','completed','dropped'])
           [floor(random() * 3) + 1],

       jsonb_build_object(
               'completed', floor(random() * 10),
               'total', 10
       ),

       numrange((random() * 50)::numeric, (random() * 50 + 50)::numeric)
FROM generate_series(1, 250000) i;