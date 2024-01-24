/*
Creating the necessary tables to conduct this project.  Utilizing information
between two tables, a Diagnosis or "dx" table and an Prescription or "rx" table.
*/

-- Create dx table.
CREATE TABLE dx (
    claim_number VARCHAR(6) PRIMARY KEY,
    patient_key VARCHAR(15),
    icd_10_code VARCHAR(50),
    date_of_service DATE
);

-- Create rx table.
CREATE TABLE rx (
    rx_number VARCHAR(5) PRIMARY KEY,
    patient_key VARCHAR(15),
    ndc_code VARCHAR(11),
    date_of_service DATE
);

-- Insert data into dx table.
INSERT INTO dx (claim_number, patient_key, icd_10_code, date_of_service)
VALUES
    ('000001', 'Patient1', 'Type2Diabetes', '2022-01-15'),
    ('000002', 'Patient1', 'Type2Diabetes', '2022-03-20'),
    ('000007', 'Patient1', 'Hypertension', '2022-02-01'),
    ('000011', 'Patient1', 'Hyperlipidemia', '2022-03-05'),
    ('000003', 'Patient2', 'Type2Diabetes', '2022-02-10'),
    ('000008', 'Patient2', 'Hyperlipidemia', '2022-03-05'),
    ('000012', 'Patient2', 'Osteoporosis', '2022-01-25'),
    ('000013', 'Patient2', 'RheumatoidArthritis', '2022-02-28'),
    ('000004', 'Patient3', 'Type2Diabetes', '2022-04-05'),
    ('000009', 'Patient3', 'Hypertension', '2022-02-15'),
    ('000014', 'Patient3', 'Osteoarthritis', '2022-03-10'),
    ('000015', 'Patient3', 'Depression', '2022-04-01'),
    ('000005', 'Patient4', 'Type2Diabetes', '2022-01-10'),
    ('000006', 'Patient4', 'Type2Diabetes', '2022-03-25'),
    ('000016', 'Patient4', 'Asthma', '2022-02-10'),
    ('000017', 'Patient4', 'ChronicObstructivePulmonaryDisease', '2022-03-15'),
    ('000018', 'Patient5', 'Hypertension', '2022-02-15'),
    ('000019', 'Patient5', 'Migraine', '2022-03-01'),
    ('000020', 'Patient5', 'GastroesophagealRefluxDisease', '2022-03-20'),
    ('000010', 'Patient6', 'Type2Diabetes', '2022-01-05'),
    ('000021', 'Patient6', 'ChronicKidneyDisease', '2022-01-20'),
    ('000022', 'Patient6', 'Obesity', '2022-02-05');

-- Insert data into rx table.
INSERT INTO rx (rx_number, patient_key, ndc_code, date_of_service)
VALUES
    ('00001', 'Patient1', '50090348300', '2022-01-20'),
    ('00002', 'Patient1', '50090348400', '2022-04-05'),
    ('00007', 'Patient1', '12345678901', '2022-02-05'),
    ('00011', 'Patient1', '98765432109', '2022-03-10'),
    ('00003', 'Patient2', '00169430301', '2022-02-15'),
    ('00008', 'Patient2', '98765432109', '2022-03-10'),
    ('00012', 'Patient2', '23456789012', '2022-01-15'),
    ('00013', 'Patient2', '34567890123', '2022-02-20'),
    ('00004', 'Patient3', '50090348300', '2022-04-10'),
    ('00009', 'Patient3', '87654321098', '2022-02-20'),
    ('00014', 'Patient3', '00169430301', '2022-03-15'),
    ('00015', 'Patient3', '98765432109', '2022-04-05'),
    ('00005', 'Patient4', '00169430301', '2022-02-01'),
    ('00006', 'Patient4', '50090348300', '2022-03-30'),
    ('00016', 'Patient4', '87654321098', '2022-01-25'),
    ('00017', 'Patient4', '23456789012', '2022-03-15'),
    ('00018', 'Patient5', '12345678901', '2022-03-05'),
    ('00019', 'Patient5', '34567890123', '2022-03-25'),
    ('00020', 'Patient5', '50090348400', '2022-04-10'),
    ('00010', 'Patient6', '23456789012', '2022-01-10'),
    ('00021', 'Patient6', '00169430301', '2022-01-20'),
    ('00022', 'Patient6', '50090348300', '2022-02-15');
    
-- Verifying it worked.
SELECT *
FROM rx;

SELECT *
FROM dx;
    
/*
Business Question 1:
How many unique patients had more than 1 claims for Type 2 diabetes in 2022?
*/

SELECT
	COUNT(*) AS num_of_patients
FROM (
	SELECT
		patient_key -- No need for DISTINCT, since we are grouping by this.
	FROM dx
	WHERE YEAR(date_of_service) = 2022
		AND icd_10_code='Type2Diabetes'
	GROUP BY patient_key
	HAVING COUNT(claim_number) > 1) AS db_of_counts;

/*
Business Question 2:
How many patients initiated (i.e., first fill) Trulicity (use ndc codes 50090348300
and 50090348400) in 2022?
*/

SELECT
	COUNT(DISTINCT patient_key) AS num_of_patients
FROM rx
WHERE YEAR(date_of_service)=2022
	AND ndc_code IN(50090348300, 50090348400);

/*
Business Question 3:
List the patient_keys for patients who filled Trulicity within 60 days of their first
diagnosis for Type 2 diabetes.
*/

SELECT
	DISTINCT(dx.patient_key) AS patients_who_filled
FROM dx
JOIN rx
	ON dx.patient_key=rx.patient_key
WHERE dx.icd_10_code LIKE 'Type2Diabetes'
	AND ndc_code IN(50090348300, 50090348400)
    AND rx.date_of_service > dx.date_of_service
    AND DATEDIFF(rx.date_of_service, dx.date_of_service) <= 60;

/*
Business Question 4:
What is the average number of days between a patient's first diagnosis of Type 2 diabetes
and their first Trulicity prescription? Exclude any patients who received Trulicity before
their Type 2 diagnosis.
*/

WITH first_date_db AS(
SELECT
	d.patient_key,
    MIN(d.date_of_service) AS first_diag,
    MIN(r.date_of_service) AS first_presc
FROM dx AS d
JOIN rx AS r
	ON d.patient_key=r.patient_key
WHERE icd_10_code LIKE 'Type2Diabetes'
	AND ndc_code IN(50090348300, 50090348400)
    AND r.date_of_service > d.date_of_service
GROUP BY d.patient_key
)
SELECT AVG(DATEDIFF(first_presc, first_diag)) AS avg_num_days
FROM first_date_db;

/*
Business Question 5:
Identify patients who switched from Rybelsus (use ndc code 00169430301) to Trulicity within
a 30 day period. We define "switching" as having no more fills of the previous drug after
the start of Trulicity.
*/

SELECT DISTINCT ryb.patient_key
FROM rx AS ryb
JOIN rx AS tru
	ON ryb.patient_key = tru.patient_key
WHERE ryb.ndc_code = 00169430301
	AND tru.ndc_code IN (50090348300, 50090348400)
    AND DATEDIFF(tru.date_of_service, ryb.date_of_service) >= 30;

/*
Business Question 6:
For patients who initiated Trulicity in 2022, what was the most common previous drug (by NDC code)
*/

WITH db_storage AS(
SELECT
	prev.ndc_code AS other_drugs,
    COUNT(prev.ndc_code) AS num_of_usage,
    RANK() OVER(ORDER BY COUNT(prev.ndc_code) DESC) AS ranking -- Using RANK incase of a tie.
FROM rx AS curr
JOIN rx AS prev
	ON curr.patient_key=prev.patient_key
WHERE curr.ndc_code IN(50090348300, 50090348400)
	AND prev.ndc_code NOT IN(50090348300, 50090348400)
    AND YEAR(curr.date_of_service)=2022 -- only need curr table to have 2022, this is for those initiating Trulicity in 2022.
    AND prev.date_of_service < curr.date_of_service -- only counting past usage.
GROUP BY prev.ndc_code
)
SELECT
	other_drugs
FROM db_storage
WHERE ranking = 1;