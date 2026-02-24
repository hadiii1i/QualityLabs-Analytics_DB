```sql
-- ========================================
-- Populating dim_time (sample 5-year calendar - from 2020 to 2025)
-- Grain: One row per calendar day
-- ========================================
-- First, a temporary function for data generation (since DataGrip has no loop, use generate_series)
INSERT INTO qms.dim_time (full_date, day_of_week, day_name, week_of_year, month_number, quarter, year, is_weekend, is_holiday, fiscal_quarter, fiscal_year)
SELECT
    d::date AS full_date,
    EXTRACT(DOW FROM d) AS day_of_week, -- 0=Sunday, 6=Saturday
    TO_CHAR(d, 'Day') AS day_name,
    EXTRACT(WEEK FROM d) AS week_of_year,
    EXTRACT(MONTH FROM d) AS month_number,
    EXTRACT(QUARTER FROM d) AS quarter,
    EXTRACT(YEAR FROM d) AS year,
    CASE WHEN EXTRACT(DOW FROM d) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend,
    FALSE AS is_holiday, -- You can add real holidays
    EXTRACT(QUARTER FROM d) AS fiscal_quarter, -- Assuming fiscal=calendar
    EXTRACT(YEAR FROM d) AS fiscal_year
FROM generate_series('2020-01-01'::date, '2025-12-31'::date, '1 day'::interval) d;
-- ========================================
-- Populating dim_organization (sample 10 records - with hierarchy and history)
-- Grain: One row per organizational unit version
-- ========================================
INSERT INTO qms.dim_organization (org_code, org_name, org_type, parent_org_code, site_location, is_active, effective_date, end_date)
VALUES
    ('ORG-001', 'Headquarters', 'Corporate', NULL, 'Tehran, Iran', TRUE, '2020-01-01', NULL),
    ('ORG-002', 'Production Plant 1', 'Manufacturing', 'ORG-001', 'Tehran Factory', TRUE, '2020-01-01', NULL),
    ('ORG-003', 'Quality Control Dept', 'Quality', 'ORG-002', 'Tehran Factory', TRUE, '2020-01-01', NULL),
    ('ORG-004', 'R&D Lab', 'Research', 'ORG-001', 'Tehran Lab', TRUE, '2020-01-01', NULL),
    ('ORG-002-OLD', 'Production Plant 1 (Old Structure)', 'Manufacturing', 'ORG-001', 'Tehran Factory', FALSE, '2018-01-01', '2020-01-01'), -- Old version
    ('ORG-005', 'Packaging Dept', 'Packaging', 'ORG-002', 'Tehran Factory', TRUE, '2020-01-01', NULL),
    ('ORG-006', 'Maintenance Team', 'Maintenance', 'ORG-002', 'Tehran Factory', TRUE, '2020-01-01', NULL),
    ('ORG-007', 'Supply Chain', 'Logistics', 'ORG-001', 'Tehran Warehouse', TRUE, '2020-01-01', NULL),
    ('ORG-008', 'Regulatory Affairs', 'Regulatory', 'ORG-001', 'Tehran Office', TRUE, '2020-01-01', NULL),
    ('ORG-009', 'HR Dept', 'Human Resources', 'ORG-001', 'Tehran Office', TRUE, '2020-01-01', NULL);
-- ========================================
-- Populating dim_product (sample 15 records - with historical versions)
-- Grain: One row per product formulation version
-- ========================================
INSERT INTO qms.dim_product (product_code, product_name, generic_name, dosage_form, strength, formulation_version, regulatory_status, approval_date, product_category, manufacturer_code, is_active, effective_date, end_date)
VALUES
    ('PROD-001', 'Aspirin', 'Acetylsalicylic Acid', 'Tablet', '100mg', 'F-01', 'Approved', '2020-05-15', 'Pain Relief', 'MANU-001', TRUE, '2020-01-01', NULL),
    ('PROD-002', 'Paracetamol', 'Acetaminophen', 'Tablet', '500mg', 'F-01', 'Active_Production', '2021-03-20', 'Fever Reducer', 'MANU-001', TRUE, '2021-01-01', NULL),
    ('PROD-003', 'Ibuprofen', 'Ibuprofen', 'Capsule', '200mg', 'F-01', 'Approved', '2020-08-10', 'Anti-Inflammatory', 'MANU-002', TRUE, '2020-01-01', NULL),
    ('PROD-001-OLD', 'Aspirin (Old Formula)', 'Acetylsalicylic Acid', 'Tablet', '100mg', 'F-00', 'Discontinued', '2018-01-01', 'Pain Relief', 'MANU-001', FALSE, '2018-01-01', '2020-01-01'), -- Old version
    ('PROD-004', 'Vitamin C', 'Ascorbic Acid', 'Tablet', '500mg', 'F-01', 'Approved', '2022-02-05', 'Supplement', 'MANU-001', TRUE, '2022-01-01', NULL),
    ('PROD-005', 'Amoxicillin', 'Amoxicillin', 'Capsule', '500mg', 'F-01', 'Active_Production', '2020-11-30', 'Antibiotic', 'MANU-003', TRUE, '2020-01-01', NULL),
    ('PROD-006', 'Lorazepam', 'Lorazepam', 'Tablet', '1mg', 'F-01', 'Approved', '2021-07-15', 'Anxiolytic', 'MANU-001', TRUE, '2021-01-01', NULL),
    ('PROD-007', 'Metformin', 'Metformin', 'Tablet', '500mg', 'F-01', 'Approved', '2020-04-25', 'Antidiabetic', 'MANU-002', TRUE, '2020-01-01', NULL),
    ('PROD-008', 'Atorvastatin', 'Atorvastatin', 'Tablet', '20mg', 'F-01', 'Approved', '2021-09-10', 'Cholesterol', 'MANU-001', TRUE, '2021-01-01', NULL),
    ('PROD-009', 'Omeprazole', 'Omeprazole', 'Capsule', '20mg', 'F-01', 'Approved', '2022-06-05', 'Acid Reducer', 'MANU-003', TRUE, '2022-01-01', NULL),
    ('PROD-010', 'Levothyroxine', 'Levothyroxine', 'Tablet', '100mcg', 'F-01', 'Approved', '2020-12-20', 'Thyroid', 'MANU-001', TRUE, '2020-01-01', NULL),
    ('PROD-011', 'Sertraline', 'Sertraline', 'Tablet', '50mg', 'F-01', 'Approved', '2021-05-30', 'Antidepressant', 'MANU-002', TRUE, '2021-01-01', NULL),
    ('PROD-012', 'Amlodipine', 'Amlodipine', 'Tablet', '5mg', 'F-01', 'Approved', '2022-03-15', 'Blood Pressure', 'MANU-001', TRUE, '2022-01-01', NULL),
    ('PROD-013', 'Simvastatin', 'Simvastatin', 'Tablet', '20mg', 'F-01', 'Approved', '2020-10-25', 'Cholesterol', 'MANU-003', TRUE, '2020-01-01', NULL),
    ('PROD-014', 'Hydrochlorothiazide', 'Hydrochlorothiazide', 'Tablet', '25mg', 'F-01', 'Approved', '2021-08-10', 'Diuretic', 'MANU-001', TRUE, '2021-01-01', NULL),
    ('PROD-015', 'Losartan', 'Losartan', 'Tablet', '50mg', 'F-01', 'Approved', '2022-01-05', 'Blood Pressure', 'MANU-002', TRUE, '2022-01-01', NULL);
-- ========================================
-- Populating dim_equipment (sample 15 records - with historical versions)
-- Grain: One row per equipment configuration version
-- ========================================
INSERT INTO qms.dim_equipment (equipment_code, equipment_name, equipment_type, manufacturer, model_number, serial_number, installation_date, calibration_status, last_calibration_date, next_calibration_date, location, operational_status, is_active, effective_date, end_date)
VALUES
    ('EQ-001', 'Tablet Press', 'Production', 'Bosch', 'TP-500', 'SN-TP-001', '2020-01-15', 'Valid', '2024-01-01', '2025-01-01', 'Production Hall 1', 'Operational', TRUE, '2020-01-01', NULL),
    ('EQ-002', 'Capsule Filler', 'Production', 'IMA', 'CF-300', 'SN-CF-001', '2020-02-20', 'Valid', '2024-02-01', '2025-02-01', 'Production Hall 2', 'Operational', TRUE, '2020-01-01', NULL),
    ('EQ-003', 'Blister Packer', 'Packaging', 'Uhlmann', 'BP-400', 'SN-BP-001', '2020-03-10', 'Valid', '2024-03-01', '2025-03-01', 'Packaging Area', 'Operational', TRUE, '2020-01-01', NULL),
    ('EQ-001-OLD', 'Tablet Press (Old Model)', 'Production', 'Bosch', 'TP-400', 'SN-TP-000', '2018-01-15', 'Expired', '2019-01-01', '2020-01-01', 'Production Hall 1', 'Retired', FALSE, '2018-01-01', '2020-01-01'), -- Old version
    ('EQ-004', 'HPLC Analyzer', 'Testing', 'Agilent', 'HPLC-1200', 'SN-HPLC-001', '2020-04-05', 'Valid', '2024-04-01', '2025-04-01', 'Quality Lab', 'Operational', TRUE, '2020-01-01', NULL),
    ('EQ-005', 'Dissolution Tester', 'Testing', 'Sotax', 'DT-700', 'SN-DT-001', '2020-05-25', 'Valid', '2024-05-01', '2025-05-01', 'Quality Lab', 'Operational', TRUE, '2020-01-01', NULL),
    ('EQ-006', 'Hardness Tester', 'Testing', 'Erweka', 'HT-300', 'SN-HT-001', '2020-06-15', 'Valid', '2024-06-01', '2025-06-01', 'Quality Lab', 'Operational', TRUE, '2020-01-01', NULL),
    ('EQ-007', 'Coating Machine', 'Production', 'Glatt', 'CM-500', 'SN-CM-001', '2020-07-10', 'Valid', '2024-07-01', '2025-07-01', 'Production Hall 3', 'Operational', TRUE, '2020-01-01', NULL),
    ('EQ-008', 'Mixing Vessel', 'Production', 'Gral', 'MV-1000', 'SN-MV-001', '2020-08-20', 'Valid', '2024-08-01', '2025-08-01', 'Production Hall 1', 'Operational', TRUE, '2020-01-01', NULL),
    ('EQ-009', 'Granulator', 'Production', 'Frewitt', 'GR-800', 'SN-GR-001', '2020-09-05', 'Valid', '2024-09-01', '2025-09-01', 'Production Hall 2', 'Operational', TRUE, '2020-01-01', NULL),
    ('EQ-010', 'Dryer', 'Production', 'Aeromatic', 'DY-600', 'SN-DY-001', '2020-10-15', 'Valid', '2024-10-01', '2025-10-01', 'Production Hall 3', 'Operational', TRUE, '2020-01-01', NULL),
    ('EQ-011', 'Bottle Filler', 'Packaging', 'Bosch', 'BF-300', 'SN-BF-001', '2020-11-25', 'Valid', '2024-11-01', '2025-11-01', 'Packaging Area', 'Operational', TRUE, '2020-01-01', NULL),
    ('EQ-012', 'Labeler', 'Packaging', 'Herma', 'LB-400', 'SN-LB-001', '2020-12-10', 'Valid', '2024-12-01', '2025-12-01', 'Packaging Area', 'Operational', TRUE, '2020-01-01', NULL),
    ('EQ-013', 'Cartoner', 'Packaging', 'IMA', 'CT-500', 'SN-CT-001', '2021-01-05', 'Valid', '2025-01-01', '2026-01-01', 'Packaging Area', 'Operational', TRUE, '2021-01-01', NULL),
    ('EQ-014', 'Storage Rack', 'Storage', 'Mecalux', 'SR-1000', 'SN-SR-001', '2021-02-15', 'Valid', '2025-02-01', '2026-02-01', 'Warehouse', 'Operational', TRUE, '2021-01-01', NULL),
    ('EQ-015', 'Cleaning System', 'Cleaning', 'Getinge', 'CS-200', 'SN-CS-001', '2021-03-20', 'Valid', '2025-03-01', '2026-03-01', 'Clean Room', 'Operational', TRUE, '2021-01-01', NULL);
-- ========================================
-- Populating dim_process_step (sample 20 records - with historical versions)
-- Grain: One row per process step configuration version
-- ========================================
INSERT INTO qms.dim_process_step (process_code, process_name, process_category, process_description, standard_duration_minutes, criticality_level, requires_validation, sequence_order, is_active, effective_date, end_date)
VALUES
    ('PROC-001', 'Weighing', 'Pre_Compression', 'Weighing of raw materials', 30, 'Medium', FALSE, 1, TRUE, '2020-01-01', NULL),
    ('PROC-002', 'Mixing', 'Pre_Compression', 'Initial mixing of ingredients', 45, 'High', TRUE, 2, TRUE, '2020-01-01', NULL),
    ('PROC-003', 'Wet Granulation', 'Pre_Compression', 'Granulation with binder', 60, 'High', TRUE, 3, TRUE, '2020-01-01', NULL),
    ('PROC-002-OLD', 'Mixing (Old Method)', 'Pre_Compression', 'Old mixing process', 60, 'High', TRUE, 2, FALSE, '2018-01-01', '2020-01-01'), -- Old version
    ('PROC-004', 'Drying', 'Pre_Compression', 'Drying of granules', 120, 'Medium', FALSE, 4, TRUE, '2020-01-01', NULL),
    ('PROC-005', 'Milling', 'Pre_Compression', 'Milling of dried granules', 30, 'Medium', FALSE, 5, TRUE, '2020-01-01', NULL),
    ('PROC-006', 'Blending', 'Pre_Compression', 'Final blending', 45, 'High', TRUE, 6, TRUE, '2020-01-01', NULL),
    ('PROC-007', 'Tablet Compression', 'Compression', 'Compressing into tablets', 90, 'High', TRUE, 7, TRUE, '2020-01-01', NULL),
    ('PROC-008', 'Capsule Filling', 'Compression', 'Filling capsules', 75, 'High', TRUE, 8, TRUE, '2020-01-01', NULL),
    ('PROC-009', 'Dedusting', 'Post_Compression', 'Removing dust', 20, 'Low', FALSE, 9, TRUE, '2020-01-01', NULL),
    ('PROC-010', 'Coating', 'Post_Compression', 'Film coating', 120, 'High', TRUE, 10, TRUE, '2020-01-01', NULL),
    ('PROC-011', 'Printing', 'Post_Compression', 'Printing on tablets', 30, 'Low', FALSE, 11, TRUE, '2020-01-01', NULL),
    ('PROC-012', 'Polishing', 'Post_Compression', 'Polishing tablets', 25, 'Low', FALSE, 12, TRUE, '2020-01-01', NULL),
    ('PROC-013', 'Weight Check', 'Quality_Control', 'Checking weight', 15, 'Medium', TRUE, 13, TRUE, '2020-01-01', NULL),
    ('PROC-014', 'Hardness Test', 'Quality_Control', 'Testing hardness', 20, 'Medium', TRUE, 14, TRUE, '2020-01-01', NULL),
    ('PROC-015', 'Dissolution Test', 'Quality_Control', 'Dissolution testing', 60, 'High', TRUE, 15, TRUE, '2020-01-01', NULL),
    ('PROC-016', 'Content Uniformity', 'Quality_Control', 'Uniformity test', 45, 'High', TRUE, 16, TRUE, '2020-01-01', NULL),
    ('PROC-017', 'Blister Packing', 'Packaging', 'Blister packaging', 50, 'Medium', FALSE, 17, TRUE, '2020-01-01', NULL),
    ('PROC-018', 'Bottle Filling', 'Packaging', 'Filling bottles', 40, 'Medium', FALSE, 18, TRUE, '2020-01-01', NULL),
    ('PROC-019', 'Labeling', 'Packaging', 'Applying labels', 25, 'Low', FALSE, 19, TRUE, '2020-01-01', NULL),
    ('PROC-020', 'Cartoning', 'Packaging', 'Final cartoning', 30, 'Low', FALSE, 20, TRUE, '2020-01-01', NULL);
-- ========================================
-- Populating dim_root_cause (sample 15 records - based on 6M)
-- Grain: One row per root cause classification version
-- ========================================
INSERT INTO qms.dim_root_cause (cause_code, cause_name, cause_category, cause_subcategory, cause_description, severity_potential, prevention_strategy, is_systemic, is_active, effective_date, end_date)
VALUES
    ('RC-001', 'Operator Error', 'Man', 'Training Issue', 'Human error due to lack of training', 'Medium', 'Improved training programs', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-002', 'Equipment Malfunction', 'Machine', 'Mechanical Failure', 'Equipment breakdown', 'High', 'Preventive maintenance', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-003', 'Material Contamination', 'Material', 'Supplier Quality', 'Contaminated raw material', 'Critical', 'Supplier audits', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-002-OLD', 'Equipment Malfunction (Old Classification)', 'Machine', 'Electrical Failure', 'Old classification of equipment issue', 'High', 'Preventive maintenance', FALSE, FALSE, '2018-01-01', '2020-01-01'), -- Old version
    ('RC-004', 'Process Deviation', 'Method', 'Procedure Error', 'Deviation from SOP', 'Medium', 'Procedure review', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-005', 'Measurement Inaccuracy', 'Measurement', 'Instrument Error', 'Inaccurate measurement tool', 'High', 'Calibration program', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-006', 'Environmental Factor', 'Environment', 'Temperature Control', 'Environmental condition issue', 'Medium', 'Environmental monitoring', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-007', 'Supplier Delay', 'Material', 'Supply Chain', 'Delay in material delivery', 'Low', 'Multiple suppliers', FALSE, TRUE, '2020-01-01', NULL),
    ('RC-008', 'Software Bug', 'Machine', 'Automation', 'Bug in control software', 'High', 'Software validation', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-009', 'Documentation Error', 'Method', 'Record Keeping', 'Error in documentation', 'Medium', 'Digital records', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-010', 'Humidity Control Failure', 'Environment', 'Climate', 'Humidity out of spec', 'High', 'Humidity controls', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-011', 'Calibration Drift', 'Measurement', 'Instrument', 'Drift in calibration', 'High', 'Frequent calibration', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-012', 'Fatigue', 'Man', 'Human Factors', 'Operator fatigue', 'Medium', 'Shift rotation', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-013', 'Contamination from Cleaning', 'Environment', 'Cleanliness', 'Residual contamination', 'High', 'Cleaning validation', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-014', 'Formula Error', 'Method', 'Formulation', 'Error in formula', 'Critical', 'Formula review', TRUE, TRUE, '2020-01-01', NULL),
    ('RC-015', 'Packaging Defect', 'Material', 'Packaging', 'Defective packaging material', 'Medium', 'Material inspection', TRUE, TRUE, '2020-01-01', NULL);
-- ========================================
-- Populating fact_deviation (sample 50 records - with realistic data)
-- Grain: One row per deviation event
-- ========================================
INSERT INTO qms.fact_deviation (deviation_number, deviation_date, id_product, id_equipment, id_organization, id_process_step, id_root_cause, batch_number, affected_quantity, rejected_quantity, rework_quantity, financial_impact, downtime_minutes, severity_level, detection_method, status, is_reportable, reported_by, reported_date, investigation_completed_date, closed_date, deviation_description)
VALUES
    ('DEV-2020-001', '2020-01-15', 1, 1, 2, 7, 2, 'BATCH-001', 1000, 200, 300, 5000.00, 60, 'Major', 'In_Process', 'Closed', FALSE, 'Operator A', '2020-01-15', '2020-01-20', '2020-01-25', 'Equipment malfunction during compression'),
    ('DEV-2020-002', '2020-02-20', 2, 2, 3, 8, 3, 'BATCH-002', 1500, 100, 400, 3000.00, 45, 'Minor', 'Final_Inspection', 'Closed', FALSE, 'QC B', '2020-02-20', '2020-02-25', '2020-03-01', 'Material contamination in filling'),
    ('DEV-2020-003', '2020-03-10', 3, 3, 5, 17, 6, 'BATCH-003', 2000, 300, 500, 7000.00, 90, 'Critical', 'Customer_Complaint', 'Closed', TRUE, 'Customer C', '2020-03-10', '2020-03-15', '2020-03-20', 'Packaging defect leading to recall'),
    ('DEV-2020-004', '2020-04-05', 4, 4, 3, 13, 5, 'BATCH-004', NULL, 0, 0, 1000.00, 30, 'Minor', 'Audit_Finding', 'Closed', FALSE, 'Auditor D', '2020-04-05', '2020-04-10', '2020-04-15', 'Weight check calibration issue'),
    ('DEV-2020-005', '2020-05-25', 5, 5, 3, 14, 11, 'BATCH-005', 800, 100, 200, 2000.00, 20, 'Medium', 'Stability_Testing', 'Closed', FALSE, 'Lab E', '2020-05-25', '2020-05-30', '2020-06-05', 'Hardness test out of spec'),;
    -- Continue with 45 more records (for brevity, 5 sample records are provided - you can use tools like Faker for generating more)
    -- For more production, you can use Python or Excel and import.
    -- e.g., DEV-2020-006 to DEV-2025-050 with random variations in ids and values.
-- ========================================
-- Final verification (optional - run in DataGrip)
-- ========================================
SELECT 'Data loaded successfully' AS status,
       (SELECT COUNT(*) FROM qms.dim_time) AS dim_time_rows,
       (SELECT COUNT(*) FROM qms.dim_organization) AS dim_org_rows,
       (SELECT COUNT(*) FROM qms.dim_product) AS dim_product_rows,
       (SELECT COUNT(*) FROM qms.dim_equipment) AS dim_equip_rows,
       (SELECT COUNT(*) FROM qms.dim_process_step) AS dim_process_rows,
       (SELECT COUNT(*) FROM qms.dim_root_cause) AS dim_cause_rows,
       (SELECT COUNT(*) FROM qms.fact_deviation) AS fact_deviation_rows;
```
SELECT COUNT(*) FROM qms.dim_time;          -- باید حدود 2192 باشد
SELECT COUNT(*) FROM qms.dim_product;       -- باید 15+ باشد
SELECT COUNT(*) FROM qms.dim_equipment;     -- باید 15+ باشد
SELECT COUNT(*) FROM qms.dim_organization;  -- باید 10+ باشد
SELECT COUNT(*) FROM qms.dim_process_step;  -- باید 20+ باشد
SELECT COUNT(*) FROM qms.dim_root_cause;    -- باید 15+ باشد
INSERT INTO qms.fact_deviation (
    deviation_number,
    deviation_date,
    id_product,
    id_equipment,
    id_organization,
    id_process_step,
    id_root_cause,
    batch_number,
    affected_quantity,
    rejected_quantity,
    rework_quantity,
    financial_impact,
    downtime_minutes,
    severity_level,
    detection_method,
    status,
    is_reportable,
    reported_by,
    reported_date,
    investigation_completed_date,
    closed_date,
    deviation_description
)
VALUES
    ('DEV-2020-001', '2020-01-15', 1, 1, 2, 7, 2, 'BATCH-001', 1000, 200, 300, 5000.00, 60, 'Major', 'In_Process', 'Closed', FALSE, 'Operator A', '2020-01-15', '2020-01-20', '2020-01-25', 'Equipment malfunction during compression'),
    ('DEV-2020-002', '2020-02-20', 2, 2, 3, 8, 3, 'BATCH-002', 1500, 100, 400, 3000.00, 45, 'Minor', 'Final_Inspection', 'Closed', FALSE, 'QC B', '2020-02-20', '2020-02-25', '2020-03-01', 'Material contamination in filling'),
    ('DEV-2020-003', '2020-03-10', 3, 3, 5, 17, 6, 'BATCH-003', 2000, 300, 500, 7000.00, 90, 'Critical', 'Customer_Complaint', 'Closed', TRUE, 'Customer C', '2020-03-10', '2020-03-15', '2020-03-20', 'Packaging defect leading to recall'),
    ('DEV-2020-004', '2020-04-05', 4, 4, 3, 13, 5, 'BATCH-004', NULL, 0, 0, 1000.00, 30, 'Minor', 'Audit_Finding', 'Closed', FALSE, 'Auditor D', '2020-04-05', '2020-04-10', '2020-04-15', 'Weight check calibration issue'),
    ('DEV-2020-005', '2020-05-25', 5, 5, 3, 14, 11, 'BATCH-005', 800, 100, 200, 2000.00, 20, 'Medium', 'Stability_Testing', 'Closed', FALSE, 'Lab E', '2020-05-25', '2020-05-30', '2020-06-05', 'Hardness test out of spec');

INSERT INTO qms.fact_deviation (
    deviation_number,
    deviation_date,
    id_product,
    id_equipment,
    id_organization,
    id_process_step,
    id_root_cause,
    batch_number,
    affected_quantity,
    rejected_quantity,
    rework_quantity,
    financial_impact,
    downtime_minutes,
    severity_level,
    detection_method,
    status,
    is_reportable,
    reported_by,
    reported_date,
    investigation_completed_date,
    closed_date,
    deviation_description
)
VALUES
    ('DEV-2020-001', '2020-01-15', 1, 1, 2, 7, 2, 'BATCH-001', 1000, 200, 300, 5000.00, 60, 'Major', 'In_Process', 'Closed', FALSE, 'Operator A', '2020-01-15', '2020-01-20', '2020-01-25', 'Equipment malfunction during compression'),
    ('DEV-2020-002', '2020-02-20', 2, 2, 3, 8, 3, 'BATCH-002', 1500, 100, 400, 3000.00, 45, 'Minor', 'Final_Inspection', 'Closed', FALSE, 'QC B', '2020-02-20', '2020-02-25', '2020-03-01', 'Material contamination in filling'),
    ('DEV-2020-003', '2020-03-10', 3, 3, 5, 17, 6, 'BATCH-003', 2000, 300, 500, 7000.00, 90, 'Critical', 'Customer_Complaint', 'Closed', TRUE, 'Customer C', '2020-03-10', '2020-03-15', '2020-03-20', 'Packaging defect leading to recall'),
    ('DEV-2020-004', '2020-04-05', 4, 4, 3, 13, 5, 'BATCH-004', NULL, 0, 0, 1000.00, 30, 'Minor', 'Audit_Finding', 'Closed', FALSE, 'Auditor D', '2020-04-05', '2020-04-10', '2020-04-15', 'Weight check calibration issue'),
    ('DEV-2020-005', '2020-05-25', 5, 5, 3, 14, 11, 'BATCH-005', 800, 100, 200, 2000.00, 20, 'Medium', 'Stability_Testing', 'Closed', FALSE, 'Lab E', '2020-05-25', '2020-05-30', '2020-06-05', 'Hardness test out of spec');