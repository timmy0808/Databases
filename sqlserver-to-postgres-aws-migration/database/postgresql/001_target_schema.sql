CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS clinical;
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS clinical.patient (
    patient_id UUID PRIMARY KEY,
    external_patient_key VARCHAR(64) NOT NULL UNIQUE,
    birth_year SMALLINT,
    blood_type VARCHAR(3),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    version_number BYTEA
);

CREATE TABLE IF NOT EXISTS clinical.donor (
    donor_id UUID PRIMARY KEY,
    external_donor_key VARCHAR(64) NOT NULL UNIQUE,
    donor_type VARCHAR(20) NOT NULL CHECK (donor_type IN ('living','deceased')),
    blood_type VARCHAR(3),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    version_number BYTEA
);

CREATE TABLE IF NOT EXISTS clinical.transplant_case (
    transplant_case_id UUID PRIMARY KEY,
    patient_id UUID NOT NULL,
    donor_id UUID NOT NULL,
    organ_type VARCHAR(20) NOT NULL,
    case_status VARCHAR(20) NOT NULL DEFAULT 'active',
    transplant_date DATE,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    version_number BYTEA
);

CREATE TABLE IF NOT EXISTS clinical.diagnostic_result (
    diagnostic_result_id UUID PRIMARY KEY,
    transplant_case_id UUID NOT NULL,
    result_type VARCHAR(100) NOT NULL,
    result_value NUMERIC(18,6),
    result_unit VARCHAR(30),
    is_abnormal BOOLEAN NOT NULL DEFAULT FALSE,
    -- DMS maps SQL Server NVARCHAR(MAX) to CLOB/TEXT during full load and CDC.
    diagnostic_payload TEXT,
    recorded_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    version_number BYTEA
);

CREATE TABLE IF NOT EXISTS audit.audit_event (
    audit_event_id BIGINT PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    action_type VARCHAR(20) NOT NULL,
    actor_key VARCHAR(100) NOT NULL,
    event_payload TEXT,
    occurred_at TIMESTAMPTZ NOT NULL
);

-- Create PKs before CDC so updates and deletes can locate rows efficiently.
-- Foreign keys can be applied after the full-load phase for higher throughput.
CREATE INDEX IF NOT EXISTS idx_diagnostic_case_recorded
ON clinical.diagnostic_result(transplant_case_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_entity_occurred
ON audit.audit_event(entity_type, entity_id, occurred_at DESC);

CREATE OR REPLACE FUNCTION clinical.get_recent_diagnostics(
    p_case_id UUID,
    p_maximum_rows INTEGER DEFAULT 100
)
RETURNS TABLE (
    diagnostic_result_id UUID,
    result_type VARCHAR,
    result_value NUMERIC,
    result_unit VARCHAR,
    is_abnormal BOOLEAN,
    diagnostic_payload JSONB,
    recorded_at TIMESTAMPTZ
)
LANGUAGE sql
AS $$
    SELECT d.diagnostic_result_id, d.result_type, d.result_value, d.result_unit,
           d.is_abnormal, d.diagnostic_payload::jsonb, d.recorded_at
    FROM clinical.diagnostic_result d
    WHERE d.transplant_case_id = p_case_id
    ORDER BY d.recorded_at DESC
    LIMIT p_maximum_rows;
$$;
