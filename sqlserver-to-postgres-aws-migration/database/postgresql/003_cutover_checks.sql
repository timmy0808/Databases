SELECT 'patient' AS table_name, COUNT(*) AS row_count FROM clinical.patient
UNION ALL SELECT 'donor', COUNT(*) FROM clinical.donor
UNION ALL SELECT 'transplant_case', COUNT(*) FROM clinical.transplant_case
UNION ALL SELECT 'diagnostic_result', COUNT(*) FROM clinical.diagnostic_result
UNION ALL SELECT 'audit_event', COUNT(*) FROM audit.audit_event
ORDER BY table_name;

SELECT COUNT(*) AS orphan_diagnostic_results
FROM clinical.diagnostic_result d
LEFT JOIN clinical.transplant_case c
  ON c.transplant_case_id = d.transplant_case_id
WHERE c.transplant_case_id IS NULL;

SELECT COUNT(*) AS invalid_json_rows
FROM clinical.diagnostic_result
WHERE diagnostic_payload IS NOT NULL
  AND jsonb_typeof(diagnostic_payload) IS NULL;

SELECT result_type, result_value, is_abnormal, diagnostic_payload
FROM clinical.diagnostic_result
WHERE diagnostic_payload ->> 'migration_marker' IN ('insert', 'update');
