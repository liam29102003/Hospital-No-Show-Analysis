-- ============================================================
-- 1. Enable Delta column mapping on the original table
-- ============================================================

ALTER TABLE medical.default.medical_appointment_no_shows
SET TBLPROPERTIES ('delta.columnMapping.mode' = 'name');


-- ============================================================
-- 2. Clean column names
-- ============================================================

ALTER TABLE medical.default.medical_appointment_no_shows
RENAME COLUMN Hipertension TO hypertension;

ALTER TABLE medical.default.medical_appointment_no_shows
RENAME COLUMN Handcap TO disability_count;

ALTER TABLE medical.default.medical_appointment_no_shows
RENAME COLUMN `NO-show` TO NO_show;


-- ============================================================
-- 3. Check disability distribution
-- ============================================================

SELECT
    disability_count,
    COUNT(*) AS record_count
FROM medical.default.medical_appointment_no_shows
GROUP BY disability_count
ORDER BY disability_count;


-- ============================================================
-- 4. Create clean table with standardized dates
-- ============================================================

CREATE OR REPLACE TABLE medical.default.medical_appointment_no_shows_clean AS
SELECT
    *,
    CAST(ScheduledDay AS TIMESTAMP) AS ScheduledDay_new,
    CAST(AppointmentDay AS DATE) AS AppointmentDay_new
FROM medical.default.medical_appointment_no_shows;


-- ============================================================
-- 5. Enable column mapping on the NEW clean table
-- ============================================================

ALTER TABLE medical.default.medical_appointment_no_shows_clean
SET TBLPROPERTIES ('delta.columnMapping.mode' = 'name');


-- ============================================================
-- 6. Drop the original date columns
-- ============================================================

ALTER TABLE medical.default.medical_appointment_no_shows_clean
DROP COLUMN ScheduledDay;

ALTER TABLE medical.default.medical_appointment_no_shows_clean
DROP COLUMN AppointmentDay;


-- ============================================================
-- 7. Rename cleaned columns
-- ============================================================

ALTER TABLE medical.default.medical_appointment_no_shows_clean
RENAME COLUMN ScheduledDay_new TO ScheduledDay;

ALTER TABLE medical.default.medical_appointment_no_shows_clean
RENAME COLUMN AppointmentDay_new TO AppointmentDay;


-- ============================================================
-- 8. Verify final schema
-- ============================================================

DESCRIBE medical.default.medical_appointment_no_shows_clean;


-- ============================================================
-- 9. Verify the dates
-- ============================================================

SELECT
    ScheduledDay,
    AppointmentDay
FROM medical.default.medical_appointment_no_shows_clean
ORDER BY ScheduledDay DESC
LIMIT 10;

-- ============================================================
-- 10. Check Bad Data
-- ============================================================

SELECT MIN(AGE), MAX(AGE) FROM medical.default.medical_appointment_no_shows_clean;

DELETE FROM medical.default.medical_appointment_no_shows_clean WHERE AGE < 0 OR AGE > 130;

-- ============================================================
-- 11. Add LEAD_TIME_DAYS column
-- ============================================================

ALTER TABLE medical.default.medical_appointment_no_shows_clean
ADD COLUMN lead_time_days INT;

UPDATE medical.default.medical_appointment_no_shows_clean
SET lead_time_days = DATEDIFF(AppointmentDay, ScheduledDay);

SELECT MIN(lead_time_days), MAX(lead_time_days) FROM medical.default.medical_appointment_no_shows_clean;

SELECT * FROM medical.default.medical_appointment_no_shows_clean where lead_time_days < 0;

DELETE FROM medical.default.medical_appointment_no_shows_clean where lead_time_days < 0;

-- ============================================================
-- 12)
