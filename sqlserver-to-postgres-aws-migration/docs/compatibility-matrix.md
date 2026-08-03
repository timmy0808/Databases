# SQL Server to PostgreSQL compatibility matrix

| SQL Server feature | PostgreSQL design | Treatment |
|---|---|---|
| `uniqueidentifier` | `uuid` | Direct type conversion |
| `bit` | `boolean` | Value conversion |
| `datetime2` | `timestamptz` | Confirm timezone semantics |
| `nvarchar(max)` JSON | `jsonb` | Parse and validate JSON |
| `rowversion` | `bigint` version column | Application-managed redesign |
| `TOP` | `LIMIT` | Query rewrite |
| `NEWID()` | `gen_random_uuid()` | Function replacement |
| `GETUTCDATE()` | `CURRENT_TIMESTAMP` | Confirm UTC session behavior |
| Stored procedure | SQL/PLpgSQL function or service code | Manual conversion |
| SQL Server Agent | EventBridge, Lambda, ECS, MWAA, or pg_cron | Operational redesign |
| Clustered index | PostgreSQL index plus physical-layout review | Do not translate blindly |
