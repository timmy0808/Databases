CREATE SCHEMA IF NOT EXISTS app;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS reporting;

COMMENT ON SCHEMA app IS 'Core multi-tenant SaaS transactional objects';
COMMENT ON SCHEMA audit IS 'Change history and security audit objects';
COMMENT ON SCHEMA reporting IS 'Views and materialized reporting objects';
