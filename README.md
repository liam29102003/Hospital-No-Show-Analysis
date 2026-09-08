# Appointment No-Show Analysis

An end-to-end SQL analytics project exploring why patients miss scheduled medical appointments, culminating in a patient-level risk-scoring model and an interactive dashboard.

## Overview

Missed medical appointments ("no-shows") waste clinical capacity and delay care for other patients. This project analyzes ~110K real-world medical appointment records from Brazil to:

- Quantify the overall no-show rate
- Identify behavioral and scheduling patterns linked to no-shows (day of week, lead time, age, SMS reminders, neighbourhood)
- Build a patient-level risk score based on each patient's own no-show history
- Surface these insights in a BI dashboard for clinic staff

## Dataset

Source data: medical appointment records for public healthcare in Brazil (~110K rows).

| Column | Description |
|---|---|
| `PatientId` | Unique patient identifier |
| `AppointmentID` | Unique appointment identifier |
| `Gender` | Patient gender (M/F) |
| `ScheduledDay` | Timestamp the appointment was booked |
| `AppointmentDay` | Date of the actual appointment |
| `Age` | Patient age |
| `Neighbourhood` | Clinic location neighbourhood |
| `Scholarship` | Enrollment in Brazil's Bolsa Família welfare program (0/1) |
| `Hipertension` | Hypertension diagnosis flag (0/1) |
| `Diabetes` | Diabetes diagnosis flag (0/1) |
| `Alcoholism` | Alcoholism flag (0/1) |
| `Handcap` | Disability count |
| `SMS_received` | Whether a reminder SMS was sent (0/1) |
| `No-show` | Target variable — "Yes" if patient missed the appointment |


## Project Structure

```
├── Scripts/
│   ├── Data_profiling.sql            -- Cleaning, column renaming, feature engineering
│   ├── Data_Exploration.sql          -- Exploratory analysis queries (EDA)
│   └── Appointment_risk_analysis.sql -- Patient-level risk scoring view
└── Dashboard/                        -- Appointment No-Show Dashboard
```

## Data Pipeline

**1. Data Profiling & Cleaning** (`Data_profiling.sql`)
- Enabled Delta column mapping to support renaming
- Renamed unclear/misspelled columns: `Hipertension` → `hypertension`, `Handcap` → `disability_count`, `` `NO-show` `` → `NO_show`
- Cast `ScheduledDay` to `TIMESTAMP` and `AppointmentDay` to `DATE`, replacing the original string columns
- Removed invalid records: negative/implausible ages (`Age < 0` or `> 130`) and appointments with a negative lead time (scheduled after the appointment date)
- Engineered a `lead_time_days` column (`DATEDIFF(AppointmentDay, ScheduledDay)`) — days between booking and the appointment
- Output: `medical.default.medical_appointment_no_shows_clean`

**2. Exploratory Data Analysis** (`Data_Exploration.sql`)
- Overall no-show rate
- No-show rate by day of week
- No-show rate by lead-time bucket (Same day / Short 1–3 days / Within a week / Long lead 8+ days)
- No-show rate by age group (Child / Teenager / Young Adult / Adult / Senior)
- No-show rate by SMS reminder status
- Top 15 highest-risk neighbourhoods (min. 100 appointments), ranked by no-show rate
- Patient-level window functions calculating each patient's prior appointment count and prior no-show count

**3. Risk Scoring** (`Appointment_risk_analysis.sql`)
- Builds `v_appointment_risk`, a view that computes for every appointment:
  - `prior_appointments` / `prior_no_shows` — running totals for that patient *before* the current appointment (via `ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING`)
  - `prior_no_show_rate` — the patient's historical no-show rate
  - `risk_tier` — classifies each appointment as:
    - **New Patient – Monitor**: no prior appointment history
    - **High Risk**: prior no-show rate ≥ 50% OR lead time ≥ 8 days
    - **Medium Risk**: prior no-show rate ≥ 20% OR lead time 4–7 days
    - **Low Risk**: everything else

## Key Findings

| Metric | Value |
|---|---|
| Total appointments | 110,521 |
| Overall no-show rate | 20.19% |
| Median lead time | 4 days |

- **Lead time is the strongest driver of no-shows.** No-show rate rises steadily from same-day appointments (lowest) through to long-lead bookings of 8+ days (highest, ~30%).
- **Day of week has a smaller effect**, with Friday showing a slightly elevated no-show rate relative to the rest of the week.
- **Neighbourhood matters.** Santos Dumont, Santa Cecilia, and Santa Clara lead the top 15 highest-risk neighbourhoods (min. 100 appointments).
- **Patient history is highly predictive.** Under the risk-tier model, roughly 20% of appointments fall into High Risk and 56% belong to new patients with no history to score yet, highlighting a large "cold start" segment worth targeting with default reminder protocols.

## Dashboard

![Image description](dashboard/hospital.png)

The **Appointment No-Show Dashboard** presents these findings for clinic operations use:

- **KPI cards**: Total Appointments, No-Show Rate, Median Lead Time, and a Risk Tier filter
- **No-Show Rate by Day of Week** — bar chart
- **No-Show Rate by Lead Time** — bar chart across the four lead-time buckets
- **Top 15 Highest-Risk Neighbourhoods** — horizontal bar chart, ranked
- **Risk Tier Breakdown** — stacked bar showing the share of appointments in each risk tier

## Tools

- **SQL** (Databricks / Delta Lake syntax — window functions, `DATEDIFF`, `TBLPROPERTIES` column mapping)
- **BI dashboard tool** for visualization (e.g., Power BI / Tableau — update this section with your specific tool)


