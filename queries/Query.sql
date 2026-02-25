SELECT fd.deviation_number, dt.year, dt.quarter, fd.severity_level
FROM qms.fact_deviation fd
         JOIN qms.dim_time dt ON fd.id_time = dt.id_time
LIMIT 5;