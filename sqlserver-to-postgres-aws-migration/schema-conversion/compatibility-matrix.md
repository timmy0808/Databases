# SQL Server to PostgreSQL compatibility matrix

| SQL Server feature | PostgreSQL target | Migration treatment |
|---|---|---|
| `UNIQUEIDENTIFIER` | `UUID` | Automatic data conversion; preserve keys |
| `DATETIME2(3)` | `TIMESTAMPTZ` | Confirm UTC and precision semantics |
| `BIT` | `BOOLEAN` | Automatic conversion |
| `NVARCHAR(MAX)` JSON | `JSONB` | Target pre-created as JSONB; validate payloads |
| `ROWVERSION` | `BYTEA` | Preserve as migration artifact or redesign app concurrency token |
| `IDENTITY BIGINT` | `BIGINT`/sequence | Reset target sequence after CDC stops |
| `TOP (@n)` | `LIMIT` | Manual stored-function conversion |
| T-SQL stored procedure | PostgreSQL SQL/PLpgSQL function | Manual conversion and testing |
| SQL Server Agent job | EventBridge, ECS, Lambda, or scheduler | Architecture redesign |
| Clustered index semantics | PostgreSQL index and table layout | Reassess from query workload |
