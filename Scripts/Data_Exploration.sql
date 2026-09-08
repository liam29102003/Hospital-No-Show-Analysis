--1: What's overall no-show rate?

SELECT NO_show, COUNT(*) as total_appointments, ROUND(COUNT(*) * 100.0 /(SELECT COUNT(*) from medical.default.medical_appointment_no_shows_clean),2) as pct_of_total from medical.default.medical_appointment_no_shows_clean 
GROUP BY NO_show;

-- 2: Day of the week distribution to No_show

SELECT DAYNAME(AppointmentDay) as appointment_day, COUNT(*) as total_appointments, SUM(CASE WHEN NO_show = 'Yes' THEN 1 ELSE 0 END) as no_shows, ROUND(SUM(CASE WHEN NO_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*),2) as rate_of_no_shows
FROM medical.default.medical_appointment_no_shows_clean
GROUP BY DAYNAME(AppointmentDay)
ORDER BY rate_of_no_shows DESC;

-- 3: Lead time Distibution

SELECT CASE WHEN lead_time_days = 0 THEN 'Same day'
WHEN lead_time_days BETWEEN 1 and 3 THEN 'Short (1-3 days)'
WHEN lead_time_days BETWEEN 4 and 7 THEN 'Within a week'
ELSE 'Long Lead (8+ days)'
END as lead_time_bucket,
COUNT(*) as total_appointments,
SUM(CASE WHEN NO_show = 'Yes' THEN 1 ELSE 0 END) as no_shows,
ROUND(SUM(CASE WHEN NO_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*),2) as rate_of_no_shows
FROM medical.default.medical_appointment_no_shows_clean
GROUP BY lead_time_bucket
ORDER BY rate_of_no_shows DESC;

-- 4: Age Groups Distribution

SELECT CASE WHEN Age BETWEEN 0 and 12 THEN 'Child'
WHEN Age BETWEEN 13 and 19 THEN 'Teenager'
WHEN Age BETWEEN 20 and 39 THEN 'Young Adult'
WHEN Age BETWEEN 40 and 59 THEN 'Adult'
ELSE 'Senior'
END as age_group,
COUNT(*) as total_appointments,
SUM(CASE WHEN NO_show = 'Yes' THEN 1 ELSE 0 END) as no_shows,
ROUND(SUM(CASE WHEN NO_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*),2) as rate_of_no_shows
FROM medical.default.medical_appointment_no_shows_clean
GROUP BY age_group
ORDER BY rate_of_no_shows DESC;

-- 5: SMS remainder distribution
SELECT CASE WHEN sms_received = 1 THEN ' Received SMS' ELSE 'No SMS'
END AS sms_status,
COUNT(*) as total_appointments,
COUNT(*) as total_appointments,
SUM(CASE WHEN NO_show = 'Yes' THEN 1 ELSE 0 END) as no_shows,
ROUND(SUM(CASE WHEN NO_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*),2) as rate_of_no_shows
from medical.default.medical_appointment_no_shows_clean
GROUP BY sms_status
ORDER BY rate_of_no_shows DESC;

-- 6: Neighbourhood Distribution

SELECT Neighbourhood,
COUNT(*) as total_appointments,
ROUND(SUM(CASE WHEN NO_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*),2) as rate_of_no_shows,
RANK() oVER (ORDER BY ROUND(SUM(CASE WHEN NO_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*),2) DESC) as risk_rank
FROM medical.default.medical_appointment_no_shows_clean
GROUP BY Neighbourhood
HAVING COUNT(*) >=100
ORDER BY rate_of_no_shows DESC
LIMIT 15;







-- patient-level risk scoring
SELECT  patientid, appointmentid, appointmentday, no_show,
COUNT(*) OVER(partition by PatientID ORDER BY AppointmentDay ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as prior_appointments,
SUM(CASE WHEN NO_show = 'Yes' THEN 1 ELSE 0 END) OVER( partition by PatientID ORDER BY AppointmentDay ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as prior_no_shows
from medical.default.medical_appointment_no_shows_clean
order by PatientId, AppointmentDay;
