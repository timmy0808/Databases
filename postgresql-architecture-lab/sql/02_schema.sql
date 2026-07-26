\set ON_ERROR_STOP on

CREATE SCHEMA IF NOT EXISTS app;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS reporting;

COMMENT ON SCHEMA app IS 'Transactional tables for the multi-tenant SaaS application.';
COMMENT ON SCHEMA audit IS 'Security events and row-change history.';
COMMENT ON SCHEMA reporting IS 'Curated analytical views and materialized views.';

