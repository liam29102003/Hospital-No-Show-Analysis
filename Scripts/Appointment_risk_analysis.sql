CREATE OR REPLACE VIEW v_appointment_risk AS

WITH patient_history AS (
    SELECT
        PatientId,
        AppointmentID,
        AppointmentDay,
        Neighbourhood,
        lead_time_days,
        sms_received,
        Scholarship,
        no_show,

        COUNT(*) OVER (
            PARTITION BY PatientId
            ORDER BY AppointmentDay
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_appointments,

        SUM(
            CASE
                WHEN no_show = 'Yes' THEN 1
                ELSE 0
            END
        ) OVER (
            PARTITION BY PatientId
            ORDER BY AppointmentDay
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_no_shows

    FROM medical.default.medical_appointment_no_shows_clean
)

SELECT
    PatientId,
    AppointmentID,
    AppointmentDay,
    Neighbourhood,
    lead_time_days,
    prior_appointments,
    prior_no_shows,

    ROUND(
        CAST(prior_no_shows AS DOUBLE)
        / NULLIF(prior_appointments, 0),
        2
    ) AS prior_no_show_rate,

    CASE
        WHEN prior_appointments = 0
            THEN 'New Patient - Monitor'

        WHEN (
            CAST(prior_no_shows AS DOUBLE)
            / NULLIF(prior_appointments, 0)
        ) >= 0.5
        OR lead_time_days >= 8
            THEN 'High Risk'

        WHEN (
            CAST(prior_no_shows AS DOUBLE)
            / NULLIF(prior_appointments, 0)
        ) >= 0.2
        OR lead_time_days BETWEEN 4 AND 7
            THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_tier

FROM patient_history;

SELECT
* 
FROM v_appointment_risk
WHERE risk_tier = 'High Risk'
ORDER BY AppointmentDay
Limit 50;

select * from v_appointment_risk;

select * from medical.default.medical_appointment_no_shows_clean
