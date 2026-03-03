ANALYZE;
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM flow WHERE status='active';
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM flow WHERE cohort_year in ('2022', '2024', '2026');
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM enrollment WHERE attendance_pct < 50;
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM "user" WHERE phone LIKE '+1231%';
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM "user" WHERE phone LIKE '+%21';
drop index idx_user_phone;
drop index idx_user_phone_hash;
create index idx_user_phone on "user"(phone);
create index idx_user_phone_hash on "user" using hash(phone);
EXPLAIN (ANALYZE, BUFFERS ) SELECT FROM "user" WHERE phone='+123122332';

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
FROM generate_series(250001, 1000000) i;
