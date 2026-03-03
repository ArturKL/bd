CREATE INDEX idx_flow_status ON flow(status);
CREATE INDEX idx_flow_cohort_year ON flow(cohort_year);
CREATE INDEX idx_enrollment_attendance ON enrollment(attendance_pct);
CREATE INDEX idx_user_phone ON "user"(phone);
CREATE INDEX idx_user_phone_hash ON "user" USING HASH(phone);