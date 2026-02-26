------------------------ Root Cause Frequency and Impact by Category (Root Cause Analysis)----------------------------
-- Purpose: Pareto analysis of root causes (6M framework),identifying systemic issues for CAPA effectiveness tracking.
-- SQL
SELECT
    rc.cause_category,
    rc.cause_name,
    COUNT(fd.id_deviation) AS frequency,
    SUM(fd.financial_impact) AS total_impact,
    AVG(fd.downtime_minutes) AS avg_downtime,
    SUM(CASE WHEN rc.is_systemic = TRUE THEN 1 ELSE 0 END) AS systemic_count
FROM qms.fact_deviation fd
         LEFT JOIN qms.dim_root_cause rc ON fd.id_root_cause = rc.id_root_cause  -- LEFT for NULL root causes
WHERE rc.is_active = TRUE
GROUP BY rc.cause_category, rc.cause_name
ORDER BY frequency DESC;